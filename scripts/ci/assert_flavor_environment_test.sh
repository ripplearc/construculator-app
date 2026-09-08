#!/bin/bash
#
# Manual test harness for scripts/ci/assert_flavor_environment.sh (CA-926).
#
# No shell-test framework (bats/shunit2/etc.) exists in this repo, so this
# follows the repo's existing bash-script conventions (set -euo pipefail,
# emoji status lines, non-zero exit on failure) rather than introducing one.
#
# Usage:
#   scripts/ci/assert_flavor_environment_test.sh
#
# Exits 0 if every case behaves as expected, non-zero on the first failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/assert_flavor_environment.sh"

FAILURES=0

# assert_exit <expected_exit_code> <description> <args...>
assert_exit() {
  local expected="$1"
  local description="$2"
  shift 2

  local output
  output="$("$TARGET" "$@" 2>&1)"
  local actual=$?

  if [[ "$actual" -eq "$expected" ]]; then
    echo "✅ PASS: ${description} (exit ${actual})"
  else
    echo "❌ FAIL: ${description} — expected exit ${expected}, got ${actual}"
    echo "   output: ${output}"
    FAILURES=$((FAILURES + 1))
  fi
}

# assert_output_contains <needle> <description> <args...>
assert_output_contains() {
  local needle="$1"
  local description="$2"
  shift 2

  local output
  output="$("$TARGET" "$@" 2>&1)"

  if [[ "$output" == *"$needle"* ]]; then
    echo "✅ PASS: ${description} (message mentions '${needle}')"
  else
    echo "❌ FAIL: ${description} — expected output to contain '${needle}'"
    echo "   output: ${output}"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "--- Matching pairs succeed ---"
assert_exit 0 "fishfood/dev matches" fishfood dev
assert_exit 0 "dogfood/qa matches" dogfood qa
assert_exit 0 "prod/prod matches" prod prod

echo "--- Mismatched pairs fail loudly ---"
assert_exit 1 "fishfood/qa mismatch fails" fishfood qa
assert_exit 1 "dogfood/dev mismatch fails" dogfood dev
assert_exit 1 "prod/dev mismatch fails" prod dev
assert_output_contains "fishfood" "mismatch message names the flavor" fishfood qa
assert_output_contains "ENVIRONMENT=qa" "mismatch message names the environment it got" fishfood qa
assert_output_contains "ENVIRONMENT=dev" "mismatch message names the environment it expected" fishfood qa

echo "--- Unknown values fail loudly, never silently pass ---"
assert_exit 1 "unknown flavor fails" staging dev
assert_output_contains "Unknown flavor" "unknown flavor message is specific" staging dev
assert_exit 1 "unknown environment fails" fishfood staging
assert_output_contains "Unknown environment" "unknown environment message is specific" fishfood staging

echo "--- Missing arguments fail loudly ---"
assert_exit 1 "no arguments fails"
assert_exit 1 "one argument fails" fishfood

if [[ "$FAILURES" -gt 0 ]]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi

echo "✅ All assert_flavor_environment.sh cases behaved as expected"
