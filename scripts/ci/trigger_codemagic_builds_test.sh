#!/bin/bash
#
# Manual test harness for scripts/ci/trigger_codemagic_builds.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH, so no request ever leaves the machine.
#
# Usage:
#   scripts/ci/trigger_codemagic_builds_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/trigger_codemagic_builds.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin"

# The fake records each request body under $FAKE_CURL_DIR/body.N, every
# argument it was called with under $FAKE_CURL_DIR/args.N, and answers
# according to FAKE_CURL_MODE:
#   ok            200 with a buildId
#   reject_first  HTTP error for the first request only, then ok
#   no_build_id   200 without a buildId
cat >"${WORK_DIR}/bin/curl" <<'EOF'
#!/bin/bash
n=$(find "$FAKE_CURL_DIR" -name 'body.*' | wc -l | tr -d ' ')
printf '%s\n' "$@" >"$FAKE_CURL_DIR/args.$((n + 1))"
body=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-d" ]; then
    body="$2"
    shift
  fi
  shift
done
count=$(find "$FAKE_CURL_DIR" -name 'body.*' | wc -l | tr -d ' ')
count=$((count + 1))
echo "$body" >"$FAKE_CURL_DIR/body.$count"
case "$FAKE_CURL_MODE" in
  reject_first)
    if [ "$count" -eq 1 ]; then
      echo '{"message":"unauthorized"}'
      exit 22
    fi
    echo "{\"buildId\":\"build-$count\"}"
    ;;
  no_build_id)
    echo '{}'
    ;;
  *)
    echo "{\"buildId\":\"build-$count\"}"
    ;;
esac
EOF
chmod +x "${WORK_DIR}/bin/curl"

# run_target <mode> <args...>
#
# Runs the target with a clean request log and the fake curl first on PATH.
# Sets OUTPUT and EXIT_CODE.
run_target() {
  local mode="$1"
  shift
  rm -rf "${WORK_DIR}/calls"
  mkdir -p "${WORK_DIR}/calls"
  rm -f "${WORK_DIR}/summary.md"
  OUTPUT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" \
      FAKE_CURL_DIR="${WORK_DIR}/calls" \
      FAKE_CURL_MODE="$mode" \
      GITHUB_STEP_SUMMARY="${WORK_DIR}/summary.md" \
      "$TARGET" "$@" 2>&1
  )"
  EXIT_CODE=$?
}

request_count() {
  find "${WORK_DIR}/calls" -name 'body.*' | wc -l | tr -d ' '
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
requests_sent() { [ "$(request_count)" -eq "$1" ]; }
summary_contains() { grep -Fq -- "$1" "${WORK_DIR}/summary.md"; }
args_contain() { grep -Fxq -- "$2" "${WORK_DIR}/calls/args.$1"; }
body_field_is() { [ "$(jq -r "$2" "${WORK_DIR}/calls/body.$1")" = "$3" ]; }

export CODEMAGIC_API_TOKEN="test-token"
export CODEMAGIC_APP_ID="test-app"

run_target ok feature/x pre-check comprehensive-check ios-debug-build
assert_true "starts every workflow when the API accepts them" exit_code_is 0
assert_true "sends one request per workflow" requests_sent 3
assert_true "sends the workflow id" body_field_is 2 .workflowId comprehensive-check
assert_true "sends the app id" body_field_is 1 .appId test-app
assert_true "disables FORCE_FAIL" body_field_is 3 .environment.variables.FORCE_FAIL false
assert_true "records each started build in the job summary" summary_contains "Started \`comprehensive-check\` on \`feature/x\`: build \`build-2\`"
assert_true "sends the token header" args_contain 1 "x-auth-token: test-token"
assert_true "posts to /builds" args_contain 1 "https://api.codemagic.io/builds"
assert_true "fails on an HTTP error" args_contain 1 "--fail-with-body"

# shellcheck disable=SC2016 # the shell metacharacters must stay literal
HOSTILE_BRANCH='a";touch pwned;"$(touch pwned)'
run_target ok "$HOSTILE_BRANCH" comprehensive-check
assert_true "keeps a hostile branch name as plain data" body_field_is 1 .branch "$HOSTILE_BRANCH"
assert_true "does not run commands hidden in a branch name" test ! -e "${WORK_DIR}/pwned"

run_target reject_first feature/x pre-check comprehensive-check
assert_true "fails when Codemagic rejects a request" exit_code_is 1
assert_true "still tries the remaining workflows after a rejection" requests_sent 2
assert_true "reports the rejected workflow" output_contains "Codemagic rejected pre-check"
assert_true "records the rejection in the job summary" summary_contains "\`pre-check\` was not started"

run_target no_build_id feature/x comprehensive-check
assert_true "fails when the response has no buildId" exit_code_is 1
assert_true "records a missing buildId in the job summary" \
  summary_contains "\`comprehensive-check\` returned no buildId"

run_target ok "" pre-check
assert_true "rejects an empty branch" exit_code_is 2

unset CODEMAGIC_API_TOKEN CODEMAGIC_APP_ID

run_target ok feature/x comprehensive-check
assert_true "fails loudly when the token is missing" exit_code_is 1
assert_true "names the missing token" output_contains "CODEMAGIC_API_TOKEN is not set"
assert_true "sends nothing when the token is missing" requests_sent 0

CODEMAGIC_API_TOKEN="test-token" CODEMAGIC_APP_ID="" run_target ok feature/x pre-check
assert_true "names the missing app id" output_contains "CODEMAGIC_APP_ID is not set"

DRY_RUN=true run_target ok feature/x pre-check comprehensive-check
assert_true "dry run succeeds without credentials" exit_code_is 0
assert_true "dry run sends nothing" requests_sent 0
assert_true "dry run names the workflow it would start" output_contains "would start comprehensive-check on feature/x"
assert_true "records the dry run in the job summary" \
  summary_contains "DRY RUN: would start \`pre-check\`"
assert_true "dry run shows the request body" output_contains '"workflowId":"comprehensive-check","branch":"feature/x"' 

run_target ok feature/x
assert_true "rejects a call with no workflow ids" exit_code_is 2

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
