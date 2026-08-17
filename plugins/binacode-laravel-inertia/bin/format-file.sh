#!/usr/bin/env bash
# PostToolUse(Edit|Write): format the file just written, and regenerate
# TypeScript types when a Data object changes. Always exits 0.
FILE=$(php -r '$i=json_decode(stream_get_contents(STDIN),true) ?: []; echo $i["tool_input"]["file_path"] ?? "";' 2>/dev/null)
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0
[ -f "artisan" ] || exit 0            # not a Laravel project: do nothing
case "$FILE" in */vendor/*|*/node_modules/*|*/storage/*|*/public/build/*) exit 0 ;; esac

case "$FILE" in
  *.php)
    [ -x ./vendor/bin/pint ] && ./vendor/bin/pint --quiet "$FILE" >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js|*.jsx)
    [ -x ./node_modules/.bin/prettier ] && ./node_modules/.bin/prettier --write "$FILE" >/dev/null 2>&1
    [ -x ./node_modules/.bin/eslint ]   && ./node_modules/.bin/eslint --fix "$FILE" >/dev/null 2>&1 ;;
esac

# A Data object changed — regenerate types so the frontend never sees a stale
# contract. This is what makes type drift structurally impossible.
case "$FILE" in
  */app/Data/*|app/Data/*)
    grep -q "spatie/laravel-typescript-transformer" composer.json 2>/dev/null \
      && php artisan typescript:transform --quiet >/dev/null 2>&1 ;;
esac
exit 0
