#!/bin/bash
#
# Manual test harness for scripts/ci/start_ios_build_and_wait.sh (CA-1534).
#
# Follows the repo's bash test convention (see assert_flavor_environment_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake Codemagic API on PATH:
#   POST .../builds             answers according to FAKE_START_MODE
#   GET  .../builds/<id>        answers the statuses in $FAKE_DIR/statuses, one
#                               per poll, and the last one for every later poll
#   POST .../builds/<id>/cancel is recorded in $FAKE_DIR/cancelled
# Every request must carry the header "x-auth-token: test-token", or the fake
# fails the way curl --fail-with-body does for a 401.
# A status of "api_error" makes the fake fail the way curl --fail-with-body does,
# "no_status" answers a build with no status, and "sigterm" sends SIGTERM to the
# script under test before answering "building".
#
# Usage:
#   scripts/ci/start_ios_build_and_wait_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/start_ios_build_and_wait.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

cat >"${WORK_DIR}/bin/curl" <<'EOF2'
#!/bin/bash
url=""
method=GET
body=""
authorized=false
while [ "$#" -gt 0 ]; do
  case "$1" in
    -X) method="$2"; shift ;;
    -d) body="$2"; shift ;;
    -H) [ "$2" = "x-auth-token: test-token" ] && authorized=true; shift ;;
  esac
  url="$1"
  shift
done
if [ "$authorized" != "true" ]; then
  echo '{"message":"unauthorized"}'
  exit 22
fi
case "$method $url" in
  "POST "*/builds)
    echo "$body" >"$FAKE_DIR/start_body"
    case "$FAKE_START_MODE" in
      reject) echo '{"message":"unauthorized"}'; exit 22 ;;
      no_build_id) echo '{}' ;;
      bad_build_id) echo '{"buildId":"../x"}' ;;
      empty_build_id) echo '{"buildId":""}' ;;
      *) echo '{"buildId":"mac1"}' ;;
    esac
    ;;
  "POST "*/cancel)
    echo "$url" >>"$FAKE_DIR/cancelled"
    echo '{}'
    ;;
  "GET "*/builds/)
    echo '{"build":{"status":"finished"}}'
    ;;
  "GET "*/builds/mac1)
    polls=$(cat "$FAKE_DIR/polls" 2>/dev/null || echo 0)
    polls=$((polls + 1))
    echo "$polls" >"$FAKE_DIR/polls"
    status=$(sed -n "${polls}p" "$FAKE_DIR/statuses")
    [ -z "$status" ] && status=$(tail -n 1 "$FAKE_DIR/statuses")
    case "$status" in
      api_error) echo '{"message":"Server Error"}'; exit 22 ;;
      no_status) echo '{"build":{}}' ;;
      sigterm)
        pid=$$
        for _ in 1 2 3 4 5; do
          pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
          case "$(ps -o args= -p "$pid")" in
            *start_ios_build_and_wait.sh*) kill -TERM "$pid"; break ;;
          esac
        done
        echo '{"build":{"status":"building"}}'
        ;;
      *) echo "{\"build\":{\"status\":\"$status\"}}" ;;
    esac
    ;;
  *) echo "unexpected request $method $url" >&2; exit 2 ;;
esac
EOF2
chmod +x "${WORK_DIR}/bin/curl"

# The fake sleep records each wait instead of waiting, so a test can count them.
cat >"${WORK_DIR}/bin/sleep" <<'EOF2'
#!/bin/bash
echo "$1" >>"$FAKE_DIR/sleeps"
EOF2
chmod +x "${WORK_DIR}/bin/sleep"

# statuses_are <status>...   one status per poll
statuses_are() {
  rm -f "${WORK_DIR}/fake/polls" "${WORK_DIR}/fake/cancelled" "${WORK_DIR}/fake/start_body" "${WORK_DIR}/fake/sleeps"
  printf '%s\n' "$@" >"${WORK_DIR}/fake/statuses"
}

run_target() {
  OUTPUT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" \
      FAKE_START_MODE="${FAKE_START_MODE:-ok}" \
      CODEMAGIC_API_TOKEN="${CODEMAGIC_API_TOKEN-test-token}" \
      CODEMAGIC_APP_ID="${CODEMAGIC_APP_ID-test-app}" \
      POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-0}" MAX_POLLS="${MAX_POLLS:-5}" \
      "$TARGET" "$@" 2>&1
  )"
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
polls_made() { [ "$(cat "${WORK_DIR}/fake/polls" 2>/dev/null || echo 0)" -eq "$1" ]; }
start_body_is() { [ "$(jq -r "$1" "${WORK_DIR}/fake/start_body")" = "$2" ]; }
cancelled_build() { grep -Fq -- "/builds/$1/cancel" "${WORK_DIR}/fake/cancelled" 2>/dev/null; }
cancelled_nothing() { [ ! -e "${WORK_DIR}/fake/cancelled" ]; }

statuses_are finished
run_target feature/x
assert_true "passes when the Mac build finished" exit_code_is 0
assert_true "starts ios-debug-build" start_body_is .workflowId ios-debug-build
assert_true "starts it on the given branch" start_body_is .branch feature/x
assert_true "starts it for the app id" start_body_is .appId test-app
assert_true "says the build finished" output_contains "build mac1 finished"

statuses_are queued preparing fetching testing building publishing finishing finished
MAX_POLLS=10 run_target feature/x
assert_true "waits through every running status until the build finishes" exit_code_is 0
assert_true "polls once per status" polls_made 8
assert_true "does not cancel a build that finished" cancelled_nothing

for ended in failed canceled timeout skipped; do
  statuses_are building "$ended"
  run_target feature/x
  assert_true "fails when the Mac build ends as $ended" exit_code_is 1
  assert_true "names the status $ended" output_contains "ended with status $ended"
  assert_true "stops polling at $ended" polls_made 2
  assert_true "does not cancel a build that already ended as $ended" cancelled_nothing
done

for unknown in warning something_new; do
  statuses_are building "$unknown"
  run_target feature/x
  assert_true "fails on the status word $unknown that the script does not know" exit_code_is 1
  assert_true "says the word $unknown is not known" output_contains "ended with status $unknown, a word this script does not know"
  assert_true "stops polling at $unknown" polls_made 2
  assert_true "cancels the Mac build when the word $unknown may mean it still runs" cancelled_build mac1
done

statuses_are building api_error
run_target feature/x
assert_true "fails when the API errors while waiting" exit_code_is 1
assert_true "says it could not read the build" output_contains "Could not read build mac1 while waiting"

statuses_are building api_error
run_target feature/x
assert_true "cancels the Mac build it can no longer watch" cancelled_build mac1

statuses_are building sigterm
run_target feature/x
assert_true "stops when it gets SIGTERM, as when Codemagic cancels the Pre-check" exit_code_is 143
assert_true "cancels the Mac build when it gets SIGTERM" cancelled_build mac1
assert_true "stops polling after SIGTERM" polls_made 2

statuses_are no_status
run_target feature/x
assert_true "fails when the API answers a build with no status" exit_code_is 1
assert_true "says the status is missing" output_contains "No build status"

statuses_are building
MAX_POLLS=3 run_target feature/x
assert_true "fails when the build does not end in time" exit_code_is 1
assert_true "stops after the last poll" polls_made 3
assert_true "says it ran out of polls" output_contains "did not end within 3 polls"
assert_true "tries to cancel the build it gave up on" cancelled_build mac1
assert_true "waits between polls but not after the last one" [ "$(wc -l <"${WORK_DIR}/fake/sleeps")" -eq 2 ]
assert_true "waits the configured interval between polls" [ "$(sort -u "${WORK_DIR}/fake/sleeps")" = 0 ]

statuses_are building
POLL_INTERVAL_SECONDS=7 MAX_POLLS=3 run_target feature/x
assert_true "sleeps for the interval it was given, not a fixed time" [ "$(sort -u "${WORK_DIR}/fake/sleeps")" = 7 ]

statuses_are finished
FAKE_START_MODE=reject run_target feature/x
assert_true "fails when Codemagic rejects the start" exit_code_is 1
assert_true "reports the rejection" output_contains "Codemagic rejected ios-debug-build"
assert_true "does not poll a build that never started" polls_made 0

FAKE_START_MODE=no_build_id run_target feature/x
assert_true "fails when the start answer has no buildId" exit_code_is 1
assert_true "says the buildId is missing" output_contains "No buildId"

FAKE_START_MODE=empty_build_id run_target feature/x
assert_true "fails when the buildId is empty" exit_code_is 1
assert_true "does not poll an empty id" polls_made 0
assert_true "says the id is not an id" output_contains "is not an id"

FAKE_START_MODE=bad_build_id run_target feature/x
assert_true "fails when the buildId is not an id" exit_code_is 1
assert_true "does not poll a malformed id" polls_made 0

# shellcheck disable=SC2016 # the shell metacharacters must stay literal
HOSTILE_BRANCH='a";touch pwned;"$(touch pwned)'
run_target "$HOSTILE_BRANCH"
assert_true "keeps a hostile branch name as plain data" start_body_is .branch "$HOSTILE_BRANCH"
assert_true "does not run commands hidden in a branch name" test ! -e "${WORK_DIR}/pwned"

run_target ""
assert_true "rejects an empty branch" exit_code_is 2

statuses_are finished
CODEMAGIC_API_TOKEN="wrong-token" run_target feature/x
assert_true "fails when Codemagic does not accept the token" exit_code_is 1
assert_true "sends the token on the start request" output_contains "Codemagic rejected ios-debug-build"

assert_true "does not trap TERM or INT, which would hold the cancel until the poll sleep ends" \
  bash -c "! grep -Eq '^trap .*(TERM|INT)' '$TARGET'"
assert_true "gives every request a time limit" \
  bash -c "[ \"\$(grep -c -- '--max-time 30 ' '$TARGET')\" = 2 ]"
assert_true "waits at most 90 polls, 30 seconds apart, when nothing overrides it" \
  bash -c "grep -Fq 'MAX_POLLS:-90}' '$TARGET' && grep -Fq 'POLL_INTERVAL_SECONDS:-30}' '$TARGET'"

CODEMAGIC_API_TOKEN="" run_target feature/x
assert_true "fails loudly when the token is missing" output_contains "CODEMAGIC_API_TOKEN is not set"

CODEMAGIC_APP_ID="" run_target feature/x
assert_true "fails loudly when the app id is missing" output_contains "CODEMAGIC_APP_ID is not set"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
