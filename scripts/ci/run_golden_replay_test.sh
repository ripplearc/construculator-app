#!/bin/bash
#
# Manual test harness for scripts/ci/run_golden_replay.sh (CA-1116).
#
# Follows scripts/ci/resolve_build_features_test.sh: no shell-test framework,
# set -uo pipefail, emoji status lines, non-zero exit on the first failure.
# The Flutter command is replaced by a stub that prints a canned test run, so
# the script's parsing and exit codes are what is under test.
#
# Usage:
#   scripts/ci/run_golden_replay_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/run_golden_replay.sh"
FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

# stub_flutter <exit code> <output line>...
stub_flutter() {
  local status="$1"; shift
  printf '%s\n' "$@" > "${WORK_DIR}/flutter_output.txt"
  cat > "${WORK_DIR}/flutter_stub.sh" <<STUB
#!/bin/bash
cat "${WORK_DIR}/flutter_output.txt"
exit $status
STUB
  chmod +x "${WORK_DIR}/flutter_stub.sh"
}

run_target() {
  FLUTTER_CMD="${WORK_DIR}/flutter_stub.sh" GOLDEN_REPLAY_GATE="${1:-0}" "$TARGET" 2>&1
}

check() {
  local name="$1" expected_status="$2" expected_text="$3" gate="${4:-0}"
  local output status
  output="$(run_target "$gate")"; status=$?
  if [ "$status" -eq "$expected_status" ] && printf '%s' "$output" | grep -q -- "$expected_text"; then
    echo "✅ $name"
  else
    echo "❌ $name (exit $status, expected $expected_status; output: $output)"
    FAILURES=$((FAILURES + 1))
  fi
}

stub_flutter 0 "00:01 +5: All tests passed!" "Golden replay: 12/134 scenarios pass (100 failed a checkpoint, 22 hit an unsupported step, 155 checkpoints unported)"
check "reports the score and passes while the gate is off" 0 "📼 Golden replay: 12/134"
check "fails under a full pass when the gate is on" 1 "needs 134/134" 1

stub_flutter 0 "Golden replay: 134/134 scenarios pass (0 failed a checkpoint, 0 hit an unsupported step, 0 checkpoints unported)"
check "passes a full pass when the gate is on" 0 "134/134, gate 1" 1

stub_flutter 1 "Golden replay: 134/134 scenarios pass (0 failed a checkpoint, 0 hit an unsupported step, 0 checkpoints unported)" "Some tests failed."
check "fails when the test run itself fails" 1 "did not run to a score"

stub_flutter 0 "00:01 +5: All tests passed!"
check "fails when no score was printed" 1 "did not run to a score"

if [ "$FAILURES" -ne 0 ]; then
  echo "❌ $FAILURES check(s) failed."
  exit 1
fi
echo "✅ All checks passed."
