#!/bin/bash
#
# Manual test harness for scripts/ci/cancel_codemagic_builds.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. curl is replaced by
# a fake on PATH that records every URL. Ids listed in FAKE_REJECT_IDS fail the
# way curl --fail-with-body does.
#
# Usage:
#   scripts/ci/cancel_codemagic_builds_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/cancel_codemagic_builds.sh"

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
for arg in "$@"; do url="$arg"; done
echo "$url" >>"$FAKE_DIR/urls"
for id in ${FAKE_REJECT_IDS:-}; do
  case "$url" in */builds/"$id"/cancel) echo '{"message":"not found"}'; exit 22 ;; esac
done
echo '{}'
EOF2
chmod +x "${WORK_DIR}/bin/curl"

run_target() {
  rm -f "${WORK_DIR}/fake/urls"
  OUTPUT="$(
    cd "$WORK_DIR" &&
      PATH="${WORK_DIR}/bin:${PATH}" FAKE_DIR="${WORK_DIR}/fake" \
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
requests_sent() { [ "$(wc -l <"${WORK_DIR}/fake/urls" 2>/dev/null | tr -d ' ')" -eq "$1" ]; }
no_requests() { [ ! -e "${WORK_DIR}/fake/urls" ]; }
asked_for() { grep -Fxq -- "$1" "${WORK_DIR}/fake/urls"; }

export CODEMAGIC_API_TOKEN=token

run_target b1 b2
assert_true "cancels every build" exit_code_is 0
assert_true "sends one request per build" requests_sent 2
assert_true "posts to the cancel endpoint of the build" asked_for "https://api.codemagic.io/builds/b2/cancel"

run_target
assert_true "does nothing without ids" exit_code_is 0
assert_true "sends nothing without ids" no_requests

FAKE_REJECT_IDS="b1" run_target b1 b2
assert_true "fails when a cancel is rejected" exit_code_is 1
assert_true "still tries the remaining builds" requests_sent 2
assert_true "names the build it could not cancel" output_contains "Could not cancel build b1"

run_target 'b1/../../x'
assert_true "rejects an id that is not alphanumeric" exit_code_is 1
assert_true "sends nothing for a bad id" no_requests

DRY_RUN=true run_target b1
assert_true "a dry run succeeds" exit_code_is 0
assert_true "a dry run cancels nothing" no_requests
assert_true "a dry run names the build" output_contains "would cancel build b1"

(unset CODEMAGIC_API_TOKEN; run_target b1; echo "$EXIT_CODE" >"${WORK_DIR}/code"; echo "$OUTPUT" >"${WORK_DIR}/out")
EXIT_CODE=$(cat "${WORK_DIR}/code")
OUTPUT=$(cat "${WORK_DIR}/out")
assert_true "fails loudly without a token" exit_code_is 1
assert_true "names the missing token" output_contains "CODEMAGIC_API_TOKEN is not set"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
