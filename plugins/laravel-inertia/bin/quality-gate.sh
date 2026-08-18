#!/usr/bin/env bash
# Stop hook: block finishing while checks fail. Exit 2 blocks; exit 1 does NOTHING.
# Scoped to changed files so the gate stays fast.
INPUT=$(cat)
[ -f "artisan" ] || exit 0            # not a Laravel project: do nothing

ACTIVE=$(printf '%s' "$INPUT" | php -r '$i=json_decode(stream_get_contents(STDIN),true) ?: []; echo empty($i["stop_hook_active"]) ? "0" : "1";' 2>/dev/null)
[ "$ACTIVE" = "1" ] && exit 0

CHANGED=$( { git diff --name-only --diff-filter=d 2>/dev/null; git diff --cached --name-only --diff-filter=d 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u )
[ -z "$CHANGED" ] && exit 0
PHP_FILES=$(printf '%s\n' "$CHANGED" | grep -E '\.php$'          | grep -v '^vendor/'       || true)
TS_FILES=$(printf  '%s\n' "$CHANGED" | grep -E '\.(ts|tsx|jsx)$' | grep -v '^node_modules/' || true)
DATA_FILES=$(printf '%s\n' "$CHANGED" | grep -E '^app/Data/'                                || true)
[ -z "$PHP_FILES" ] && [ -z "$TS_FILES" ] && exit 0

FAILED=""
add() { FAILED="${FAILED}
[$1]
$2"; }

if [ -n "$DATA_FILES" ] && grep -q "spatie/laravel-typescript-transformer" composer.json 2>/dev/null; then
  BEFORE=$(git status --porcelain 2>/dev/null | sort)
  php artisan typescript:transform --quiet >/dev/null 2>&1 || add "typescript:transform" "the command failed — check the Data classes"
  AFTER=$(git status --porcelain 2>/dev/null | sort)
  [ "$BEFORE" != "$AFTER" ] && add "generated types" "Generated TypeScript was stale and has been regenerated. Review and include it in the commit."
fi

if [ -n "$PHP_FILES" ]; then
  [ -x ./vendor/bin/pint ] && { OUT=$(printf '%s\n' "$PHP_FILES" | tr '\n' '\0' | xargs -0 ./vendor/bin/pint --test 2>&1) || add pint "$OUT"; }

  # PHPStan paths on the CLI override phpstan.neon's `paths:` — analysing
  # every changed file (not just app/) would surface pre-existing errors in
  # tests/, database/, etc. that the project never asked to be checked.
  # Restrict to whatever phpstan.neon actually declares (default: app/).
  # NOTE: only reads paths: from the top-level config file, not from an
  # `includes:` chain. That under-scopes rather than over-scopes (falls
  # through to the app/ default below), which is the safe direction for a
  # gate that can only block — never widen what gets analysed.
  if [ -x ./vendor/bin/phpstan ]; then
    STAN_FILES=$(printf '%s\n' "$PHP_FILES" | php -r '
      $norm = function ($p) {
          if (preg_match("/^([\x27\"])(.*)\\1\$/", $p, $qm)) { $p = $qm[2]; }   // drop a matching quote pair
          $p = preg_replace("#^%currentWorkingDirectory%/#", "", $p);
          $p = preg_replace("#^\./#", "", $p, 1);                              // strip one leading ./, not a run of ./ chars
          return rtrim($p, "/");
      };
      $roots = [];
      // same candidate filenames/order as init-project.php:52 — keep both in sync
      foreach (["phpstan.neon", "phpstan.neon.dist", "phpstan.dist.neon"] as $f) {
          if (!is_file($f)) continue;
          $inPaths = false;
          foreach (file($f) as $line) {
              $line = rtrim($line, "\r\n");
              if (!$inPaths && preg_match("/^\s*paths\s*:\s*(.*)\$/", $line, $pm)) {
                  $rest = trim(preg_replace("/(^|\s)#.*\$/", "", $pm[1]));     // strip an inline comment first, then trim
                  if ($rest === "") { $inPaths = true; continue; }             // block style: list follows
                  if (preg_match("/^\[(.*)\]\$/", $rest, $fm)) {               // flow style: paths: [app, tests]
                      foreach (explode(",", $fm[1]) as $item) {
                          $item = trim($item);
                          if ($item !== "") $roots[] = $norm($item);
                      }
                  }
                  break;
              }
              if ($inPaths) {
                  if (preg_match("/^\s*-\s*(\S+)/", $line, $m)) { $roots[] = $norm($m[1]); continue; }
                  break;
              }
          }
          break;
      }
      if (!$roots) $roots = ["app"];   // no config, or no paths: key -> Larastan default
      foreach (explode("\n", trim(stream_get_contents(STDIN))) as $file) {
          if ($file === "") continue;
          foreach ($roots as $r) {
              if ($r !== "" && ($file === $r || strpos($file, $r."/") === 0)) { echo $file, "\n"; break; }
          }
      }
    ' 2>/dev/null)
    [ -n "$STAN_FILES" ] && { OUT=$(printf '%s\n' "$STAN_FILES" | tr '\n' '\0' | xargs -0 ./vendor/bin/phpstan analyse --no-progress --error-format=raw 2>&1) || add phpstan "$OUT"; }
  fi
fi
if [ -n "$TS_FILES" ]; then
  [ -x ./node_modules/.bin/tsc ]    && { OUT=$(./node_modules/.bin/tsc --noEmit 2>&1) || add tsc "$OUT"; }
  [ -x ./node_modules/.bin/eslint ] && { OUT=$(printf '%s\n' "$TS_FILES" | tr '\n' '\0' | xargs -0 ./node_modules/.bin/eslint 2>&1) || add eslint "$OUT"; }
fi

[ -n "$FAILED" ] && { echo "Quality gate failed. Fix these before finishing:${FAILED}" >&2; exit 2; }
exit 0
