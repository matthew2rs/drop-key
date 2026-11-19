#!/bin/bash
# Smoke test. Uses a throwaway Keychain service, so it never touches your real keys.
# No network. macOS only. Run: ./tests/smoke_test.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export DROPKEY_SERVICE="drop-key-selftest-$$"
TMP="$(mktemp -d)"
LEFT_BEFORE="$(ls "${TMPDIR:-/tmp}"/dropkey.* 2>/dev/null | wc -l | tr -d ' ' || true)"
cleanup() {
  for n in t-plain t-tricky; do /usr/bin/security delete-generic-password -s "$DROPKEY_SERVICE" -a "$n" >/dev/null 2>&1 || true; done
  rm -rf "$TMP"
}
trap cleanup EXIT
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; exit 1; }

# 1. The app source compiles.
/usr/bin/osacompile -o "$TMP/Drop Key.app" src/DropKey.applescript && pass "app compiles" || fail "app compiles"

# 2. Point a test copy of the script at the throwaway service.
sed "s/property serviceName : \"drop-key\"/property serviceName : \"$DROPKEY_SERVICE\"/" src/DropKey.applescript > "$TMP/t.applescript"
grep -q "$DROPKEY_SERVICE" "$TMP/t.applescript" || fail "service swap"

# 3. Save a plain key and a nasty one (quotes, backslash, dollar, backticks, spaces).
TRICKY='sk-te"st\ va$l `x` '"'"'q'"'"'z'
[ "$(osascript "$TMP/t.applescript" --save t-plain abc123)" = "saved" ] && pass "save plain" || fail "save plain"
[ "$(osascript "$TMP/t.applescript" --save t-tricky "$TRICKY")" = "saved" ] && pass "save tricky" || fail "save tricky"

# 4. Read back exactly.
[ "$(bin/dropkey get t-plain)" = "abc123" ] && pass "get plain" || fail "get plain"
[ "$(bin/dropkey get t-tricky)" = "$TRICKY" ] && pass "get tricky round-trips exactly" || fail "get tricky"

# 5. Overwrite works (-U).
osascript "$TMP/t.applescript" --save t-plain newvalue >/dev/null
[ "$(bin/dropkey get t-plain)" = "newvalue" ] && pass "overwrite" || fail "overwrite"

# 6. has / list (names only, no values).
bin/dropkey has t-plain && pass "has (present)" || fail "has (present)"
if bin/dropkey has nope-missing; then fail "has (missing)"; else pass "has (missing)"; fi
L="$(bin/dropkey list)"
if echo "$L" | grep -qx t-plain && echo "$L" | grep -qx t-tricky; then pass "list shows names"; else fail "list shows names"; fi
if echo "$L" | grep -q newvalue; then fail "list leaked a value"; else pass "list shows no values"; fi

# 7. Bad names are refused.
if osascript "$TMP/t.applescript" --save 'bad name;rm' x >/dev/null 2>&1; then fail "bad name refused"; else pass "bad name refused"; fi

# 8. No temp files left behind.
LEFT_AFTER="$(ls "${TMPDIR:-/tmp}"/dropkey.* 2>/dev/null | wc -l | tr -d ' ' || true)"
if [ "$LEFT_AFTER" != "$LEFT_BEFORE" ]; then fail "temp file left behind"; else pass "no temp files left"; fi

# 9. Delete.
bin/dropkey delete t-plain >/dev/null
if bin/dropkey has t-plain; then fail "delete"; else pass "delete"; fi

# 10. The helpers the dialogs use (trim pasted whitespace, name check).
/usr/bin/osacompile -o "$TMP/t.scpt" "$TMP/t.applescript"
H() { osascript -e "set s to load script POSIX file \"$TMP/t.scpt\"" -e "$1"; }
[ "$(H 'return s'"'"'s trimEnds("  abc" & linefeed & tab)')" = "abc" ] && pass "trims pasted whitespace" || fail "trim"
[ "$(H 'return s'"'"'s trimEnds("   ")')" = "" ] && pass "blank paste becomes empty" || fail "blank trim"
[ "$(H 'return s'"'"'s validName("openai-api_2.prod")')" = "true" ] && pass "good name accepted" || fail "good name"
[ "$(H 'return s'"'"'s validName("Bad Name")')" = "false" ] && pass "space in name refused" || fail "space name"

echo "All smoke tests passed (macOS $(sw_vers -productVersion))."
