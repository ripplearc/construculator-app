#!/bin/bash
#
# Manual test harness for scripts/ci/post_commit_status.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH that records the URL and the request body.
#
# Usage:
#   scripts/ci/post_commit_status_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/post_commit_status.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

# FAKE_CURL_FAIL=true makes the fake fail the way curl --fail-with-body does.
cat >"${WORK_DIR}/bin/curl" <<'EOF2'
#!/bin/bash
body=""
url=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = "-d" ]; then body="$2"; shift; fi
  url="$1"
  shift
done
echo "$url" >"$FAKE_DIR/url"
echo "$body" >"$FAKE_DIR/body"
if [ "${FAKE_CURL_FAIL:-false}" = "true" ]; then
  echo '{"message":"Resource not accessible by integration"}'
  exit 22
fi
echo '{"id":1}'
EOF2
chmod +x "${WORK_DIR}/bin/curl"

# run_target <args...>   Sets OUTPUT and EXIT_CODE.
run_target() {
  rm -f "${WORK_DIR}"/fake/*
  OUTPUT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" \
      GH_REPO="owner/repo" GITHUB_TOKEN="token" \
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
posted_url_is() { [ "$(cat "${WORK_DIR}/fake/url")" = "$1" ]; }
body_field_is() { [ "$(jq -r "$1" "${WORK_DIR}/fake/body")" = "$2" ]; }
body_has_no() { [ "$(jq -r "has(\"$1\")" "${WORK_DIR}/fake/body")" = "false" ]; }
nothing_posted() { [ ! -e "${WORK_DIR}/fake/url" ]; }

run_target abc123 "Ios Debug Build" success "Skipped: no iOS-related files changed" "https://example.test/run/1"
assert_true "posts successfully" exit_code_is 0
assert_true "posts to the statuses endpoint of the commit" posted_url_is "https://api.github.com/repos/owner/repo/statuses/abc123"
assert_true "sends the context" body_field_is .context "Ios Debug Build"
assert_true "sends the state" body_field_is .state success
assert_true "sends the description" body_field_is .description "Skipped: no iOS-related files changed"
assert_true "sends the target url" body_field_is .target_url "https://example.test/run/1"

run_target abc123 "Ios Debug Build" success "No link"
assert_true "leaves target_url out when none is given" body_has_no target_url

# shellcheck disable=SC2016 # the shell metacharacters must stay literal
run_target abc123 ctx success 'quote " and $(touch pwned) and newline
second line'
assert_true "keeps hostile text as plain data" body_field_is .context ctx
assert_true "does not run commands hidden in the description" test ! -e "${WORK_DIR}/pwned"

FAKE_CURL_FAIL=true run_target abc123 ctx success "d"
assert_true "fails when GitHub rejects the status" exit_code_is 1
assert_true "shows GitHub's reason" output_contains "Resource not accessible by integration"

DRY_RUN=true run_target abc123 ctx success "d"
assert_true "a dry run succeeds" exit_code_is 0
assert_true "a dry run posts nothing" nothing_posted
assert_true "a dry run shows the status" output_contains "would post to abc123"

run_target abc123 ctx bogus "d"
assert_true "rejects an unknown state" exit_code_is 2
assert_true "posts nothing for an unknown state" nothing_posted

run_target abc123 ctx success
assert_true "rejects a missing description" exit_code_is 2

(cd "$WORK_DIR" && PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" GITHUB_TOKEN="" GH_REPO="owner/repo" "$TARGET" abc123 ctx success d >"${WORK_DIR}/out" 2>&1)
EXIT_CODE=$?
OUTPUT="$(cat "${WORK_DIR}/out")"
assert_true "fails loudly without a token" exit_code_is 1
assert_true "names the missing token" output_contains "GITHUB_TOKEN is not set"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
