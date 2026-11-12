#!/bin/bash
#
# Manual test harness for the startup and drive-leg time limits in
# scripts/perf/capture_perf_run.sh.
#
# Runs the script against a fake fvm whose `flutter drive` and `flutter run` can
# hang, the way they do when the phone's USB link freezes `adb install` or the app
# never renders a first frame, so the time limits and retries can be checked
# without hardware.
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
  run)
    echo run >>"$FAKE_DIR/run_calls"
    echo "$*" >>"$FAKE_DIR/run_args"
    calls="$(wc -l <"$FAKE_DIR/run_calls")"
    if [[ "$STARTUP_HANG_MODE" == fail-first && "$calls" -eq 1 ]]; then
      exit 1
    fi
    if [[ "$STARTUP_HANG_MODE" == always || ( "$STARTUP_HANG_MODE" == first && "$calls" -eq 1 ) ]]; then
      exec sleep 60
    fi ;;
  *) ;;
esac
EOF2
cat >"${WORK_DIR}/bin/adb" <<'EOF2'
#!/bin/bash
echo "$*" >>"$FAKE_DIR/adb_calls"
[[ "$1" == devices ]] && printf 'List of devices attached\n%s\tdevice\n' "$FAKE_SERIAL"
exit 0
EOF2
cat >"${WORK_DIR}/ensure_attached" <<'EOF2'
#!/bin/bash
echo attach >>"$FAKE_DIR/attach_calls"
exit "${ATTACH_EXIT:-0}"
EOF2
REAL_TIMEOUT="$(command -v timeout || command -v gtimeout)"
cat >"${WORK_DIR}/bin/timeout" <<EOF2
#!/bin/bash
echo "\$*" >>"\$FAKE_DIR/timeout_calls"
exec "$REAL_TIMEOUT" "\$@"
EOF2
chmod +x "${WORK_DIR}/bin/fvm" "${WORK_DIR}/bin/adb" "${WORK_DIR}/bin/timeout" "${WORK_DIR}/ensure_attached"

# run_target <drive hang mode> [startup hang mode]: runs the script and fills
# OUTPUT / STATUS / DRIVE_CALLS / RUN_CALLS / ATTACH_CALLS / FORWARD_CLEARS.
# Normal fake launches finish at once and hung ones are cut at the limit, so the
# limit is 5 seconds, far above what a normal launch takes on a busy machine.
run_target() {
  local state="${WORK_DIR}/state"
  rm -rf "$state" "${WORK_DIR}/out"; mkdir -p "$state"
  : >"$state/drive_calls"; : >"$state/run_calls"; : >"$state/attach_calls"
  : >"$state/run_args"; : >"$state/adb_calls"; : >"$state/timeout_calls"
  OUTPUT="$(cd "$REPO_ROOT" && PATH="${WORK_DIR}/bin:$PATH" FAKE_DIR="$state" \
    FAKE_SERIAL="$SERIAL" HANG_MODE="$1" STARTUP_HANG_MODE="${2:-never}" \
    PERF_DRIVE_TIMEOUT="${DRIVE_TIMEOUT_FOR_TEST:-5}" PERF_STARTUP_TIMEOUT="${STARTUP_TIMEOUT_FOR_TEST:-5}" \
    ENSURE_ATTACH_SCRIPT="${WORK_DIR}/ensure_attached" \
    bash "$TARGET" --device-id "$SERIAL" --output-dir "${WORK_DIR}/out" --iterations 1 2>&1)"
  STATUS=$?
  DRIVE_CALLS="$(wc -l <"$state/drive_calls" | tr -d ' ')"
  RUN_CALLS="$(wc -l <"$state/run_calls" | tr -d ' ')"
  ATTACH_CALLS="$(wc -l <"$state/attach_calls" | tr -d ' ')"
  FORWARD_CLEARS="$(grep -c 'forward --remove-all' "$state/adb_calls" | tr -d ' ')"
  RUN_ARGS_FILE="$state/run_args"
  TIMEOUT_CALLS_FILE="$state/timeout_calls"
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

run_target never first
check "a hung startup launch is cut off, the phone re-attached, and the launch retried to success" \
  "$([[ "$STATUS" -eq 0 && "$RUN_CALLS" -eq 4 && "$ATTACH_CALLS" -eq 1 ]] && echo yes || echo no)"
check "the retry of a hung launch keeps the arguments of the first attempt" \
  "$([[ "$(wc -l <"$RUN_ARGS_FILE" | tr -d ' ')" -ge 2 && "$(sed -n 1p "$RUN_ARGS_FILE")" == "$(sed -n 2p "$RUN_ARGS_FILE")" && "$(sed -n 1p "$RUN_ARGS_FILE")" == *"--purge-persistent-cache"* ]] && echo yes || echo no)"
check "the adb forwards are cleared once in the startup retry and once before each drive leg" \
  "$([[ "$FORWARD_CLEARS" -eq 3 ]] && echo yes || echo no)"
check "every startup launch and every re-attach runs under a time limit that also kills" \
  "$([[ "$(grep -c 'fvm flutter run' "$TIMEOUT_CALLS_FILE")" -eq 4 && "$(grep -c -- '--kill-after=30 5 fvm flutter run' "$TIMEOUT_CALLS_FILE")" -eq 4 && "$(grep -c -- '--kill-after=30 6m bash' "$TIMEOUT_CALLS_FILE")" -eq 1 && "$(grep -c -- '^30 adb' "$TIMEOUT_CALLS_FILE")" -eq 1 ]] && echo yes || echo no)"

run_target never always
check "a startup launch that always hangs fails after 3 attempts and no drive leg starts" \
  "$([[ "$STATUS" -ne 0 && "$RUN_CALLS" -eq 3 && "$DRIVE_CALLS" -eq 0 && "$OUTPUT" == *"startup launch failed after 3 attempts"* ]] && echo yes || echo no)"
check "the phone is re-attached between startup attempts but not after the last one" \
  "$([[ "$ATTACH_CALLS" -eq 2 ]] && echo yes || echo no)"
check "the log names the exit code of a launch cut at its time limit" \
  "$([[ "$OUTPUT" == *"attempt 1/3 failed (exit 124,"* ]] && echo yes || echo no)"

run_target never fail-first
check "a startup launch that exits with an error is retried to success after one re-attach" \
  "$([[ "$STATUS" -eq 0 && "$RUN_CALLS" -eq 4 && "$ATTACH_CALLS" -eq 1 && "$OUTPUT" == *"attempt 1/3 failed (exit 1,"* ]] && echo yes || echo no)"

ATTACH_EXIT=1 run_target never first
check "a failed re-attach does not stop the retry" \
  "$([[ "$STATUS" -eq 0 && "$RUN_CALLS" -eq 4 && "$OUTPUT" == *"re-attach failed"* ]] && echo yes || echo no)"

STARTUP_TIMEOUT_FOR_TEST=abc run_target never
check "a bad PERF_STARTUP_TIMEOUT stops the script before any launch" \
  "$([[ "$STATUS" -ne 0 && "$RUN_CALLS" -eq 0 && "$OUTPUT" == *"PERF_STARTUP_TIMEOUT must be"* ]] && echo yes || echo no)"

[[ "$FAILURES" -eq 0 ]] || { echo "$FAILURES case(s) failed"; echo "$OUTPUT" | tail -15; exit 1; }
