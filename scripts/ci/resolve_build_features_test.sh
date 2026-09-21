#!/bin/bash
#
# Manual test harness for scripts/ci/resolve_build_features.sh (CA-925).
#
# No shell-test framework (bats/shunit2/etc.) exists in this repo, so this
# follows the repo's existing bash-script conventions (set -euo pipefail,
# emoji status lines, non-zero exit on failure) rather than introducing one.
#
# Usage:
#   scripts/ci/resolve_build_features_test.sh
#
# Exits 0 if every case behaves as expected, non-zero on the first failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/resolve_build_features.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# run_target <flavor>
#
# Runs the target script from a temp working directory that has its own
# config/flavors/<flavor>.json fixture, so real flavor manifests under
# config/flavors/ don't need to cover the empty/unknown-feature cases.
run_target() {
  local flavor="$1"
  (cd "$WORK_DIR" && "$TARGET" "$flavor" 2>&1)
}

write_fixture() {
  local flavor="$1"
  local features_json="$2"
  mkdir -p "${WORK_DIR}/config/flavors"
  cat >"${WORK_DIR}/config/flavors/${flavor}.json" <<EOF
{
  "features": ${features_json}
}
EOF
}

# assert_exit <expected_exit_code> <description> <flavor>
assert_exit() {
  local expected="$1"
  local description="$2"
  local flavor="$3"

  local output
  output="$(run_target "$flavor")"
  local actual=$?

  if [[ "$actual" -eq "$expected" ]]; then
    echo "✅ PASS: ${description} (exit ${actual})"
  else
    echo "❌ FAIL: ${description} — expected exit ${expected}, got ${actual}"
    echo "   output: ${output}"
    FAILURES=$((FAILURES + 1))
  fi
}

# assert_output_contains <needle> <description> <flavor>
assert_output_contains() {
  local needle="$1"
  local description="$2"
  local flavor="$3"

  local output
  output="$(run_target "$flavor")"

  if [[ "$output" == *"$needle"* ]]; then
    echo "✅ PASS: ${description} (message mentions '${needle}')"
  else
    echo "❌ FAIL: ${description} — expected output to contain '${needle}'"
    echo "   output: ${output}"
    FAILURES=$((FAILURES + 1))
  fi
}

# assert_resolved_file_contains <flavor> <needle> <description>
assert_resolved_file_contains() {
  local flavor="$1"
  local needle="$2"
  local description="$3"

  run_target "$flavor" >/dev/null
  local resolved="${WORK_DIR}/build/generated/flavors/${flavor}.json"

  if [[ ! -f "$resolved" ]]; then
    echo "❌ FAIL: ${description} — ${resolved} was not written"
    FAILURES=$((FAILURES + 1))
    return
  fi

  if grep -q "$needle" "$resolved"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description} — expected ${resolved} to contain '${needle}'"
    echo "   contents: $(cat "$resolved")"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "--- A listed known feature resolves to true ---"
write_fixture "with-calculator" '["calculator"]'
assert_exit 0 "resolves cleanly" "with-calculator"
assert_resolved_file_contains "with-calculator" '"ENABLE_CALCULATOR": true' "calculator listed -> ENABLE_CALCULATOR: true"

echo "--- An empty features list resolves every known feature to false ---"
write_fixture "no-features" '[]'
assert_exit 0 "resolves cleanly" "no-features"
assert_resolved_file_contains "no-features" '"ENABLE_CALCULATOR": false' "empty list -> ENABLE_CALCULATOR: false"

echo "--- An unknown feature name fails loudly, never silently passes ---"
write_fixture "bad-feature" '["not-a-real-feature"]'
assert_exit 1 "unknown feature fails" "bad-feature"
assert_output_contains "not-a-real-feature" "error names the bad value" "bad-feature"
assert_output_contains "calculator" "error names the known set" "bad-feature"

echo "--- A flavor file with no \"features\" list fails loudly ---"
mkdir -p "${WORK_DIR}/config/flavors"
: >"${WORK_DIR}/config/flavors/empty-file.json"
assert_exit 1 "empty file fails" "empty-file"
assert_output_contains 'no "features" list' "error names the missing list" "empty-file"

echo '{}' >"${WORK_DIR}/config/flavors/empty-object.json"
assert_exit 1 "empty object fails" "empty-object"
assert_output_contains 'no "features" list' "error names the missing list" "empty-object"

echo "--- KNOWN_FEATURES stays in sync with the Feature enum ---"
FEATURE_ENUM_FILE="${SCRIPT_DIR}/../../lib/libraries/config/feature_availability.dart"
dart_features="$(sed -n '/^enum Feature {/,/^}/p' "$FEATURE_ENUM_FILE" \
  | grep -oE '^  [a-z][A-Za-z0-9]*' | tr -d ' ' | sort)"
bash_features="$(sed -n 's/^KNOWN_FEATURES=(\(.*\))$/\1/p' "$TARGET" | tr ' ' '\n' | sort)"
if [[ "$dart_features" == "$bash_features" ]]; then
  echo "✅ PASS: KNOWN_FEATURES matches the Feature enum"
else
  echo "❌ FAIL: KNOWN_FEATURES has drifted from the Feature enum"
  echo "   Dart enum cases: $(echo "$dart_features" | tr '\n' ' ')"
  echo "   Bash KNOWN_FEATURES: $(echo "$bash_features" | tr '\n' ' ')"
  FAILURES=$((FAILURES + 1))
fi

echo "--- Missing flavor argument fails loudly ---"
(cd "$WORK_DIR" && "$TARGET" >/tmp/resolve_build_features_test_noargs.out 2>&1)
NOARG_EXIT=$?
if [[ "$NOARG_EXIT" -ne 0 ]]; then
  echo "✅ PASS: no arguments fails (exit ${NOARG_EXIT})"
else
  echo "❌ FAIL: no arguments fails — expected non-zero exit, got ${NOARG_EXIT}"
  FAILURES=$((FAILURES + 1))
fi
rm -f /tmp/resolve_build_features_test_noargs.out

if [[ "$FAILURES" -gt 0 ]]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi

echo "✅ All resolve_build_features.sh cases behaved as expected"
