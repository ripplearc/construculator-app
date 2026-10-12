#!/bin/bash
#
# Manual test harness for scripts/ci/post_pr_comment.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH that records the URL and the request body.
#
# Usage:
#   scripts/ci/post_pr_comment_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/post_pr_comment.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/fake"

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
nothing_posted() { [ ! -e "${WORK_DIR}/fake/url" ]; }
posted_url_is() { [ "$(cat "${WORK_DIR}/fake/url")" = "$1" ]; }

# shellcheck disable=SC2016 # the shell metacharacters must stay literal
printf 'Line one\n\nLine `two` with "quotes" and $(touch pwned)\n' >"${WORK_DIR}/body.md"
run_target 7 "${WORK_DIR}/body.md"
assert_true "posts the comment" exit_code_is 0
assert_true "posts to the issue comments endpoint" posted_url_is "https://api.github.com/repos/owner/repo/issues/7/comments"
assert_true "sends the file text as the body" test "$(jq -r .body "${WORK_DIR}/fake/body")" = "$(cat "${WORK_DIR}/body.md")"
assert_true "does not run commands hidden in the text" test ! -e "${WORK_DIR}/pwned"

: >"${WORK_DIR}/empty.md"
run_target 7 "${WORK_DIR}/empty.md"
assert_true "an empty file is not an error" exit_code_is 0
assert_true "an empty file posts nothing" nothing_posted

run_target 7 "${WORK_DIR}/missing.md"
assert_true "a missing file posts nothing" nothing_posted

FAKE_CURL_FAIL=true run_target 7 "${WORK_DIR}/body.md"
assert_true "fails when GitHub rejects the comment" exit_code_is 1
assert_true "shows GitHub's reason" output_contains "Resource not accessible by integration"

DRY_RUN=true run_target 7 "${WORK_DIR}/body.md"
assert_true "a dry run succeeds" exit_code_is 0
assert_true "a dry run posts nothing" nothing_posted
assert_true "a dry run shows the text" output_contains "Line one"

run_target 7
assert_true "rejects a missing body file argument" exit_code_is 2

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
