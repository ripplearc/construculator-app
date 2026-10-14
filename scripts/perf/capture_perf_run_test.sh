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
cat >"${WORK_DIR}/ensure_attached" <<'EOF2'
#!/bin/bash
echo attach >>"$FAKE_DIR/attach_calls"
EOF2
chmod +x "${WORK_DIR}/bin/fvm" "${WORK_DIR}/bin/adb" "${WORK_DIR}/ensure_attached"

# run_target <hang mode>: runs the script and fills OUTPUT / STATUS / DRIVE_CALLS.
run_target() {
  local state="${WORK_DIR}/state"
  rm -rf "$state" "${WORK_DIR}/out"; mkdir -p "$state"; : >"$state/drive_calls"; : >"$state/attach_calls"
  OUTPUT="$(cd "$REPO_ROOT" && PATH="${WORK_DIR}/bin:$PATH" FAKE_DIR="$state" \
    FAKE_SERIAL="$SERIAL" HANG_MODE="$1" PERF_DRIVE_TIMEOUT="${DRIVE_TIMEOUT_FOR_TEST:-1}" \
    ENSURE_ATTACH_SCRIPT="${WORK_DIR}/ensure_attached" \
    bash "$TARGET" --device-id "$SERIAL" --output-dir "${WORK_DIR}/out" --iterations 1 2>&1)"
  STATUS=$?
  DRIVE_CALLS="$(wc -l <"$state/drive_calls" | tr -d ' ')"
  ATTACH_CALLS="$(wc -l <"$state/attach_calls" | tr -d ' ')"
}

check() {
  local name="$1" ok="$2"
  if [[ "$ok" == yes ]]; then echo "✅ $name"; else echo "❌ $name"; FAILURES=$((FAILURES + 1)); fi
}

if ! command -v timeout >/dev/null && ! command -v gtimeout >/dev/null; then
  echo "⏭️  skipped: GNU timeout not found (brew install coreutils)"
  exit 0
fi

run_target first
check "a hung first drive attempt is cut off and retried to success" \
  "$([[ "$STATUS" -eq 0 && "$DRIVE_CALLS" -eq 3 ]] && echo yes || echo no)"
check "the phone is re-attached after the hung attempt only" \
  "$([[ "$ATTACH_CALLS" -eq 1 ]] && echo yes || echo no)"

run_target always
check "a drive leg that always hangs fails after 3 attempts" \
  "$([[ "$STATUS" -ne 0 && "$DRIVE_CALLS" -eq 3 && "$OUTPUT" == *"drive leg failed after 3 attempts"* ]] && echo yes || echo no)"
check "the phone is re-attached between attempts but not after the last one" \
  "$([[ "$ATTACH_CALLS" -eq 2 ]] && echo yes || echo no)"

DRIVE_TIMEOUT_FOR_TEST=abc run_target first
check "a bad PERF_DRIVE_TIMEOUT stops the script before any drive attempt" \
  "$([[ "$STATUS" -ne 0 && "$DRIVE_CALLS" -eq 0 && "$OUTPUT" == *"PERF_DRIVE_TIMEOUT must be"* ]] && echo yes || echo no)"

[[ "$FAILURES" -eq 0 ]] || { echo "$FAILURES case(s) failed"; echo "$OUTPUT" | tail -15; exit 1; }
