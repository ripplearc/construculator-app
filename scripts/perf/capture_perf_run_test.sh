#!/bin/bash
#
# Manual test harness for the drive-leg time limit in scripts/perf/capture_perf_run.sh.
#
# Runs the script against a fake fvm whose `flutter drive` can hang, the way it
# does when the phone's USB link freezes `adb install`, so the time limit and
# retry can be checked without hardware.
#
# Usage:
#   scripts/perf/capture_perf_run_test.sh
#
# Exits 0 if every case behaves as expected, non-zero otherwise.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${SCRIPT_DIR}/capture_perf_run.sh"
SERIAL="3A091FDJG005FU"

FAILURES=0
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "${WORK_DIR}/bin"
cat >"${WORK_DIR}/bin/fvm" <<'EOF2'
#!/bin/bash
[[ "$1" == flutter ]] || exit 0
case "$2" in
  --version) echo "Flutter fake" ;;
  drive)
    echo drive >>"$FAKE_DIR/drive_calls"
    calls="$(wc -l <"$FAKE_DIR/drive_calls")"
    if [[ "$HANG_MODE" == always || ( "$HANG_MODE" == first && "$calls" -eq 1 ) ]]; then
      exec sleep 60
    fi
    mkdir -p "$PERF_OUTPUT_DIR"
    echo '{}' >"$PERF_OUTPUT_DIR/fake.json" ;;
  *) ;;
esac
EOF2
cat >"${WORK_DIR}/bin/adb" <<'EOF2'
#!/bin/bash
[[ "$1" == devices ]] && printf 'List of devices attached\n%s\tdevice\n' "$FAKE_SERIAL"
exit 0
EOF2
chmod +x "${WORK_DIR}/bin/fvm" "${WORK_DIR}/bin/adb"

# run_target <hang mode>: runs the script and fills OUTPUT / STATUS / DRIVE_CALLS.
run_target() {
  local state="${WORK_DIR}/state"
  rm -rf "$state" "${WORK_DIR}/out"; mkdir -p "$state"; : >"$state/drive_calls"
  OUTPUT="$(cd "$REPO_ROOT" && PATH="${WORK_DIR}/bin:$PATH" FAKE_DIR="$state" \
    FAKE_SERIAL="$SERIAL" HANG_MODE="$1" PERF_DRIVE_TIMEOUT=1 \
    USBIPD_BIN="${WORK_DIR}/no-usbipd" \
    bash "$TARGET" --device-id "$SERIAL" --output-dir "${WORK_DIR}/out" --iterations 1 2>&1)"
  STATUS=$?
  DRIVE_CALLS="$(wc -l <"$state/drive_calls" | tr -d ' ')"
}

check() {
  local name="$1" ok="$2"
  if [[ "$ok" == yes ]]; then echo "✅ $name"; else echo "❌ $name"; FAILURES=$((FAILURES + 1)); fi
}

run_target first
check "a hung first drive attempt is cut off and retried to success" \
  "$([[ "$STATUS" -eq 0 && "$DRIVE_CALLS" -eq 3 ]] && echo yes || echo no)"

run_target always
check "a drive leg that always hangs fails after 3 attempts" \
  "$([[ "$STATUS" -ne 0 && "$DRIVE_CALLS" -eq 3 && "$OUTPUT" == *"drive leg failed after 3 attempts"* ]] && echo yes || echo no)"

[[ "$FAILURES" -eq 0 ]] || { echo "$FAILURES case(s) failed"; echo "$OUTPUT" | tail -15; exit 1; }
