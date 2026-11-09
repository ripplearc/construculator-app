#!/bin/bash
#
# Manual test harness for scripts/perf/make_no_streaming_adb_sdk.sh.
#
# Builds the SDK folder from a fake SDK whose `adb` records its arguments, then
# calls the wrapper the way Flutter does and checks what the real adb received.
#
# Usage:
#   scripts/perf/make_no_streaming_adb_sdk_test.sh
#
# Exits 0 if every case behaves as expected, non-zero otherwise.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/make_no_streaming_adb_sdk.sh"

FAILURES=0
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

REAL_SDK="${WORK_DIR}/real-sdk"
mkdir -p "$REAL_SDK/platform-tools" "$REAL_SDK/build-tools" "$REAL_SDK/licenses"
cat >"$REAL_SDK/platform-tools/adb" <<'EOF2'
#!/bin/bash
printf '%s\n' "$@" >"$FAKE_ADB_LOG"
exit "${FAKE_ADB_EXIT:-0}"
EOF2
chmod +x "$REAL_SDK/platform-tools/adb"
echo fastboot >"$REAL_SDK/platform-tools/fastboot"

check() {
  local name="$1" ok="$2"
  if [[ "$ok" == yes ]]; then echo "✅ $name"; else echo "❌ $name"; FAILURES=$((FAILURES + 1)); fi
}

# adb_lines <args...>: runs the wrapper and prints what the real adb got, one
# argument per line.
adb_lines() {
  FAKE_ADB_LOG="${WORK_DIR}/adb.log" "${SHIM}/platform-tools/adb" "$@"
  cat "${WORK_DIR}/adb.log"
}

# adb_received <args...>: the same, joined with spaces on one line.
adb_received() {
  adb_lines "$@" | paste -sd ' ' -
}

SHIM="$(ANDROID_HOME="$REAL_SDK" bash "$TARGET" "${WORK_DIR}/shim-sdk")"

check "the script prints the output folder" \
  "$([[ "$SHIM" == "${WORK_DIR}/shim-sdk" ]] && echo yes || echo no)"
check "other SDK folders and platform-tools files are linked to the real SDK" \
  "$([[ -L "$SHIM/build-tools" && -L "$SHIM/platform-tools/fastboot" && -L "$SHIM/licenses" ]] && echo yes || echo no)"
check "an install gets --no-streaming right after the install word" \
  "$([[ "$(adb_received -s PHONE install -t -r app.apk)" == "-s PHONE install --no-streaming -t -r app.apk" ]] && echo yes || echo no)"
check "an uninstall is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE uninstall com.example.app)" == "-s PHONE uninstall com.example.app" ]] && echo yes || echo no)"
check "pm install inside adb shell is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE shell pm install -r /data/local/tmp/a.apk)" == "-s PHONE shell pm install -r /data/local/tmp/a.apk" ]] && echo yes || echo no)"
check "a push is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE push a.apk /data/local/tmp/a.apk)" == "-s PHONE push a.apk /data/local/tmp/a.apk" ]] && echo yes || echo no)"

OUTPUT="$(ANDROID_HOME="$REAL_SDK" bash "$TARGET" "$REAL_SDK" 2>&1)"
check "the real SDK is refused as the output folder" \
  "$([[ $? -ne 0 || "$OUTPUT" == *"must not be the real SDK"* ]] && echo yes || echo no)"

check "an APK path with a space reaches the real adb as one argument" \
  "$([[ "$(adb_lines -s PHONE install -r "my app.apk")" == $'-s\nPHONE\ninstall\n--no-streaming\n-r\nmy app.apk' ]] && echo yes || echo no)"

FAKE_ADB_EXIT=7 FAKE_ADB_LOG="${WORK_DIR}/adb.log" "${SHIM}/platform-tools/adb" -s PHONE install a.apk
check "the exit code of the real adb is returned" \
  "$([[ $? -eq 7 ]] && echo yes || echo no)"

check "install as the argument of pm in exec-out is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE exec-out pm install -r x)" == "-s PHONE exec-out pm install -r x" ]] && echo yes || echo no)"
check "install as a logcat tag is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE logcat -s install)" == "-s PHONE logcat -s install" ]] && echo yes || echo no)"
check "install as a push source is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE push install /tmp/)" == "-s PHONE push install /tmp/" ]] && echo yes || echo no)"
check "a serial named install does not get the flag in its place" \
  "$([[ "$(adb_received -s install install a.apk)" == "-s install install --no-streaming a.apk" ]] && echo yes || echo no)"
check "install-multiple is passed through unchanged" \
  "$([[ "$(adb_received -s PHONE install-multiple a.apk b.apk)" == "-s PHONE install-multiple a.apk b.apk" ]] && echo yes || echo no)"

OUTPUT="$(ANDROID_HOME="$REAL_SDK/" bash "$TARGET" "$REAL_SDK" 2>&1)"; STATUS=$?
check "the real SDK is refused when ANDROID_HOME has a trailing slash" \
  "$([[ "$STATUS" -ne 0 && "$OUTPUT" == *"must not be the real SDK"* && -e "$REAL_SDK/platform-tools/fastboot" ]] && echo yes || echo no)"

ln -s "$REAL_SDK" "${WORK_DIR}/link-to-sdk"
OUTPUT="$(ANDROID_HOME="${WORK_DIR}/link-to-sdk" bash "$TARGET" "$REAL_SDK" 2>&1)"; STATUS=$?
check "the real SDK is refused when ANDROID_HOME is a symlink to it" \
  "$([[ "$STATUS" -ne 0 && "$OUTPUT" == *"must not be the real SDK"* && -e "$REAL_SDK/platform-tools/fastboot" ]] && echo yes || echo no)"

OUTPUT="$(cd "$WORK_DIR" && ANDROID_HOME="real-sdk" bash "$TARGET" "relative-out" 2>&1)"; STATUS=$?
check "a relative ANDROID_HOME gives links that point at the real SDK" \
  "$([[ "$STATUS" -eq 0 && -e "${WORK_DIR}/relative-out/platform-tools/fastboot" && -e "${WORK_DIR}/relative-out/build-tools" ]] && echo yes || echo no)"

OUTPUT="$(ANDROID_HOME="${WORK_DIR}/missing" bash "$TARGET" "${WORK_DIR}/other" 2>&1)"
check "an SDK without an adb stops the script" \
  "$([[ "$OUTPUT" == *"is not an executable adb"* ]] && echo yes || echo no)"

[[ "$FAILURES" -eq 0 ]] || { echo "$FAILURES case(s) failed"; exit 1; }
