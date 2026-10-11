#!/bin/bash
#
# Manual test harness for scripts/ci/main_needs_ios_build.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH that answers from the files FAKE_MAIN_BODY and FAKE_CHECKS_BODY
# and records every URL it is asked for.
#
# Usage:
#   scripts/ci/main_needs_ios_build_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/main_needs_ios_build.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin"

# A request whose URL contains "/commits/main" gets FAKE_MAIN_BODY. A request
# for "check-runs" gets FAKE_CHECKS_BODY. An empty file makes the fake fail
# the way curl --fail-with-body does (exit 22 with the body).
cat >"${WORK_DIR}/bin/curl" <<'EOF'
#!/bin/bash
url=""
for arg in "$@"; do url="$arg"; done
echo "$url" >>"$FAKE_DIR/urls"
case "$url" in
  */commits/main) body_file="$FAKE_DIR/main.json" ;;
  *check-runs*) body_file="$FAKE_DIR/checks.json" ;;
  *) echo "unexpected url $url" >&2; exit 2 ;;
esac
if [ ! -s "$body_file" ]; then
  echo '{"message":"Server Error"}'
  exit 22
fi
cat "$body_file"
EOF
chmod +x "${WORK_DIR}/bin/curl"

mkdir -p "${WORK_DIR}/fake"

# set_main <json>   set_checks <json>   (empty string makes the call fail)
set_main() { printf '%s' "$1" >"${WORK_DIR}/fake/main.json"; }
set_checks() { printf '%s' "$1" >"${WORK_DIR}/fake/checks.json"; }

# check_run <app slug> <status> <conclusion|null> [name]
check_run() {
  local name="${4:-Ios Debug Build}"
  local conclusion="$3"
  [ "$conclusion" != "null" ] && conclusion="\"$conclusion\""
  printf '{"name":"%s","status":"%s","conclusion":%s,"app":{"slug":"%s"}}' \
    "$name" "$2" "$conclusion" "$1"
}

# run_target
#
# Sets STDOUT_TEXT, STDERR_TEXT and EXIT_CODE. Extra variables come from the caller.
run_target() {
  rm -f "${WORK_DIR}/fake/urls"
  STDOUT_TEXT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" \
      FAKE_DIR="${WORK_DIR}/fake" \
      GH_REPO="owner/repo" \
      GITHUB_TOKEN="token" \
      "$TARGET" 2>"${WORK_DIR}/stderr"
  )"
  EXIT_CODE=$?
  STDERR_TEXT="$(cat "${WORK_DIR}/stderr")"
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   stdout: ${STDOUT_TEXT}"
    echo "   stderr: ${STDERR_TEXT}"
    FAILURES=$((FAILURES + 1))
  fi
}

answer_is() { [ "$STDOUT_TEXT" = "$1" ]; }
exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }
stderr_contains() { echo "$STDERR_TEXT" | grep -Fq -- "$1"; }
asked_for() { grep -Fq -- "$1" "${WORK_DIR}/fake/urls"; }

set_main '{"sha":"abc123"}'

set_checks '{"check_runs":[]}'
run_target
assert_true "builds when main has no iOS check run" answer_is build
assert_true "exits 0 so the workflow carries on" exit_code_is 0
assert_true "says there is no result yet, not that the lookup failed" stderr_contains "has no Ios Debug Build result from Codemagic yet"

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed success)]}"
run_target
assert_true "skips when Codemagic already passed on main's tip" answer_is skip
assert_true "says which commit it looked at" stderr_contains "abc123"

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed failure)]}"
run_target
assert_true "skips when Codemagic already failed on main's tip" answer_is skip

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd in_progress null)]}"
run_target
assert_true "skips while a Codemagic build is still running" answer_is skip

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd queued null)]}"
run_target
assert_true "skips while a Codemagic build is queued" answer_is skip

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed cancelled)]}"
run_target
assert_true "builds again after a canceled run" answer_is build

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed timed_out)]}"
run_target
assert_true "builds again after a timed-out run" answer_is build

set_checks "{\"check_runs\":[$(check_run github-actions completed success)]}"
run_target
assert_true "ignores a same-named check run from another app" answer_is build

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed success 'Comprehensive Check')]}"
run_target
assert_true "ignores a Codemagic check run with another name" answer_is build

set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed cancelled),$(check_run codemagic-ci-cd completed success)]}"
run_target
assert_true "skips when any earlier run on the tip finished" answer_is skip

set_checks ''
run_target
assert_true "builds when the check-runs lookup fails" answer_is build
assert_true "exits 0 when the lookup fails" exit_code_is 0
assert_true "explains the failed lookup on stderr" stderr_contains "Could not read check runs"

set_checks 'not json'
run_target
assert_true "builds when the answer is not JSON" answer_is build
assert_true "explains the unreadable answer" stderr_contains "could not be read"

set_checks '{}'
run_target
assert_true "builds when the answer has no check_runs" answer_is build

set_checks '{"check_runs":[]}'
set_main ''
run_target
assert_true "builds when the tip of main cannot be read" answer_is build
assert_true "explains the failed branch lookup" stderr_contains "Could not read the tip of main"

set_main '{"nosha":true}'
run_target
assert_true "builds when main's answer has no sha" answer_is build

set_main '{"sha":"abc123"}'
set_checks "{\"check_runs\":[$(check_run codemagic-ci-cd completed success)]}"
MAIN_SHA="fff999" run_target
assert_true "uses MAIN_SHA without asking for main" answer_is skip
assert_true "looks up check runs for MAIN_SHA" asked_for "commits/fff999/check-runs"
assert_true "does not read the branch when MAIN_SHA is given" bash -c "! grep -Fq '/commits/main' '${WORK_DIR}/fake/urls'"

run_target
assert_true "asks only for the iOS check name" asked_for "check_name=Ios%20Debug%20Build"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
