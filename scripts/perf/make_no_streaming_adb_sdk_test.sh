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
printf '%s\n' "$*" >"$FAKE_ADB_LOG"
EOF2
chmod +x "$REAL_SDK/platform-tools/adb"
echo fastboot >"$REAL_SDK/platform-tools/fastboot"

check() {
  local name="$1" ok="$2"
  if [[ "$ok" == yes ]]; then echo "✅ $name"; else echo "❌ $name"; FAILURES=$((FAILURES + 1)); fi
}

# adb_received <args...>: runs the wrapper and prints what the real adb got.
adb_received() {
  FAKE_ADB_LOG="${WORK_DIR}/adb.log" "${SHIM}/platform-tools/adb" "$@"
  cat "${WORK_DIR}/adb.log"
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

OUTPUT="$(ANDROID_HOME="${WORK_DIR}/missing" bash "$TARGET" "${WORK_DIR}/other" 2>&1)"
check "an SDK without an adb stops the script" \
  "$([[ "$OUTPUT" == *"is not an executable adb"* ]] && echo yes || echo no)"

[[ "$FAILURES" -eq 0 ]] || { echo "$FAILURES case(s) failed"; exit 1; }
