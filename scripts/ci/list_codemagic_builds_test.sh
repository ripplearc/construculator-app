#!/bin/bash
#
# Manual test harness for scripts/ci/list_codemagic_builds.sh (CA-1346).
#
# Follows the repo's bash test convention (see plan_runcheck_test.sh): no
# shell-test framework, non-zero exit if any case fails. curl is replaced by a
# fake Codemagic on PATH that answers every request from $FAKE_DIR/body.json and
# records the URL and headers it was asked with. A missing body file makes the
# fake fail the way curl --fail-with-body does.
#
# Usage:
#   scripts/ci/list_codemagic_builds_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/list_codemagic_builds.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

cat >"${WORK_DIR}/bin/curl" <<'EOF2'
#!/bin/bash
echo "$*" >>"$FAKE_DIR/requests"
if [ ! -s "$FAKE_DIR/body.json" ]; then
  echo '{"message":"Server Error"}'
  exit 22
fi
cat "$FAKE_DIR/body.json"
EOF2
chmod +x "${WORK_DIR}/bin/curl"

set_body() { printf '%s' "$1" >"${WORK_DIR}/fake/body.json"; }

run_target() {
  rm -f "${WORK_DIR}/fake/requests"
  STDOUT_TEXT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" \
      CODEMAGIC_API_TOKEN="${TOKEN-secret-token}" CODEMAGIC_APP_ID="${APP_ID-app123}" \
      "$TARGET" "$@" 2>"${WORK_DIR}/stderr"
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

output_is() { [ "$(jq -c "$1" <<< "$STDOUT_TEXT")" = "$2" ]; }
stderr_contains() { grep -Fq -- "$1" <<< "$STDERR_TEXT"; }
output_hides_token() { ! grep -Fq secret-token <<< "${STDOUT_TEXT} ${STDERR_TEXT}"; }
sent() { grep -Fq -- "$1" "${WORK_DIR}/fake/requests"; }
exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }

set_body '{"builds":[
  {"_id":"b1","workflowId":"ios-debug-build","status":"queued","commit":{"hash":"aaa111"},"createdAt":"2026-10-27T19:00:00Z"},
  {"_id":"b2","workflowId":"comprehensive-check","status":"building","commit":{"hash":"bbb222"},"createdAt":"2026-10-27T19:01:00Z"}]}'
run_target feature/x
assert_true "exits 0" exit_code_is 0
assert_true "lists the id, workflow, status and commit of every build" output_is . \
  '[{"id":"b1","workflow":"ios-debug-build","status":"queued","commit":"aaa111","createdAt":"2026-10-27T19:00:00Z"},{"id":"b2","workflow":"comprehensive-check","status":"building","commit":"bbb222","createdAt":"2026-10-27T19:01:00Z"}]'
assert_true "names the statuses it saw" stderr_contains "Statuses seen: building, queued"
assert_true "gives the number of builds read" stderr_contains "Builds read: 2"
assert_true "names the fields Codemagic sent" stderr_contains "Fields on a build: _id, commit, createdAt, status, workflowId"
assert_true "asks for the app and the branch" sent "builds?appId=app123&branch=feature%2Fx"
assert_true "sends the token in the x-auth-token header" sent "x-auth-token: secret-token"
assert_true "never prints the token" output_hides_token

set_body '[{"id":"b3","workflow":{"id":"pre-check"},"status":"finished","commitHash":"ccc333","created_at":"2026-10-27T18:00:00Z"}]'
run_target main
assert_true "reads a plain list and the other field spellings" output_is . \
  '[{"id":"b3","workflow":"pre-check","status":"finished","commit":"ccc333","createdAt":"2026-10-27T18:00:00Z"}]'

set_body '{"builds":[{"_id":"b4"}]}'
run_target main
assert_true "a field Codemagic does not send is null" output_is '.[0]' \
  '{"id":"b4","workflow":null,"status":null,"commit":null,"createdAt":null}'

set_body '{"builds":[]}'
run_target main
assert_true "a branch with no builds gives an empty list" output_is . '[]'
assert_true "exits 0 for an empty list" exit_code_is 0

set_body '{"applications":[]}'
run_target main
assert_true "an answer with no list of builds fails" exit_code_is 1
assert_true "says the list is missing" stderr_contains "has no list of builds"

set_body '{"builds":{"b1":{"status":"queued"}}}'
run_target main
assert_true "builds that are not a list fail" exit_code_is 1

set_body '{"builds":["b1","b2"]}'
run_target main
assert_true "a list of ids instead of builds fails with a message" exit_code_is 1
assert_true "says the answer has no list of builds" stderr_contains "has no list of builds"

set_body '{"builds":"oops"}'
run_target main
assert_true "builds that are text fail" exit_code_is 1

set_body '<html>Bad gateway</html>'
run_target main
assert_true "an answer that is not JSON fails" exit_code_is 1
assert_true "the failure message shows the start of the answer" stderr_contains "Bad gateway"

set_body '{"builds":[]}'
run_target 'odd branch&x=1 #2'
assert_true "a branch name with & space and # is encoded in the request" sent "branch=odd%20branch%26x%3D1%20%232"
assert_true "gives up on a request that takes more than 15 seconds" sent "--max-time 15"

rm -f "${WORK_DIR}/fake/body.json"
run_target main
assert_true "a failed request fails" exit_code_is 1
assert_true "says which branch could not be listed" stderr_contains "Could not list the Codemagic builds of main"

TOKEN="" run_target main
assert_true "a missing token fails" exit_code_is 1
assert_true "says the token is not set" stderr_contains "CODEMAGIC_API_TOKEN"

APP_ID="" run_target main
assert_true "a missing app id fails" exit_code_is 1

run_target
assert_true "no branch fails with the usage line" exit_code_is 2

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed."
  exit 1
fi
echo "✅ All list_codemagic_builds cases passed."
