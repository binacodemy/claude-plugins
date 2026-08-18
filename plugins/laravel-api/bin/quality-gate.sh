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
  [ -x ./vendor/bin/pint ]    && { OUT=$(echo "$PHP_FILES" | xargs ./vendor/bin/pint --test 2>&1) || add pint "$OUT"; }
  [ -x ./vendor/bin/phpstan ] && { OUT=$(echo "$PHP_FILES" | xargs ./vendor/bin/phpstan analyse --no-progress --error-format=raw 2>&1) || add phpstan "$OUT"; }
fi
if [ -n "$TS_FILES" ]; then
  [ -x ./node_modules/.bin/tsc ]    && { OUT=$(./node_modules/.bin/tsc --noEmit 2>&1) || add tsc "$OUT"; }
  [ -x ./node_modules/.bin/eslint ] && { OUT=$(echo "$TS_FILES" | xargs ./node_modules/.bin/eslint 2>&1) || add eslint "$OUT"; }
fi

[ -n "$FAILED" ] && { echo "Quality gate failed. Fix these before finishing:${FAILED}" >&2; exit 2; }
exit 0
