#!/bin/bash
#
# Manual test harness for scripts/ci/build_ios_when_needed.sh (CA-1534).
#
# Follows the repo's bash test convention (see assert_flavor_environment_test.sh):
# no shell-test framework, non-zero exit if any case fails. The script is copied
# next to a fake start_ios_build_and_wait.sh that records its arguments and the
# app id it was given, so no request ever leaves the machine.
#
# Usage:
#   scripts/ci/build_ios_when_needed_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/scripts"
cp "${SCRIPT_DIR}/build_ios_when_needed.sh" "${WORK_DIR}/scripts/build_ios_when_needed.sh"
cat >"${WORK_DIR}/scripts/start_ios_build_and_wait.sh" <<'EOF2'
#!/bin/bash
echo "$1 app=$CODEMAGIC_APP_ID" >"$(dirname "$0")/started"
exit "${FAKE_WAIT_EXIT:-0}"
EOF2
TARGET="${WORK_DIR}/scripts/build_ios_when_needed.sh"
STARTED="${WORK_DIR}/scripts/started"

# run_target <decision text|-> <branch> [env assignments...]
# "-" leaves the decision file out.
run_target() {
  local decision="$1" branch="$2"
  shift 2
  rm -f "$STARTED" "${WORK_DIR}/decision.txt"
  [ "$decision" = "-" ] || printf '%s\n' "$decision" >"${WORK_DIR}/decision.txt"
  OUTPUT="$(env CODEMAGIC_APP_ID="" CM_PROJECT_ID="" "$@" "$TARGET" "$branch" "${WORK_DIR}/decision.txt" 2>&1)"
  EXIT_CODE=$?
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   output: ${OUTPUT}"
    FAILURES=$((FAILURES + 1))
  fi
}

exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }
output_contains() { echo "$OUTPUT" | grep -Fq -- "$1"; }
started_with() { [ "$(cat "$STARTED" 2>/dev/null)" = "$1" ]; }
did_not_start() { [ ! -e "$STARTED" ]; }

run_target "skip: no iOS-related files changed (4 files checked)" feature/x
assert_true "skips the Mac build when the decision is skip" did_not_start
assert_true "passes when it skips" exit_code_is 0
assert_true "says it skipped" output_contains "Skipped: skip: no iOS-related files changed"

run_target "run: ios/Podfile matches ios/" feature/x
assert_true "builds when the decision is run" started_with "feature/x app="

run_target "" feature/x
assert_true "builds when the decision is empty" started_with "feature/x app="

run_target - feature/x
assert_true "builds when there is no decision file" started_with "feature/x app="

run_target "maybe" feature/x
assert_true "builds when the decision is neither run nor skip" started_with "feature/x app="

run_target "SKIP: shouting" feature/x
assert_true "reads only a lower-case skip: as a skip" started_with "feature/x app="

run_target "skipped: x" feature/x
assert_true "reads only skip: as a skip, not a word that starts with skip" started_with "feature/x app="

run_target "run: skip: tricky reason" feature/x
assert_true "reads a skip word inside a run reason as a run" started_with "feature/x app="

run_target "run: x" feature/x FAKE_WAIT_EXIT=1
assert_true "fails when the Mac build does not finish" exit_code_is 1

run_target "run: x" feature/x CM_PROJECT_ID=cm-app
assert_true "uses CM_PROJECT_ID as the app id when CODEMAGIC_APP_ID is empty" started_with "feature/x app=cm-app"

run_target "run: x" feature/x CM_PROJECT_ID=cm-app CODEMAGIC_APP_ID=own-app
assert_true "prefers CODEMAGIC_APP_ID when it is set" started_with "feature/x app=own-app"

run_target "skip: x" ""
assert_true "a skip needs no branch" exit_code_is 0

OUTPUT="$("$TARGET" feature/x 2>&1)"
EXIT_CODE=$?
assert_true "rejects a call without the decision file argument" exit_code_is 2

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
