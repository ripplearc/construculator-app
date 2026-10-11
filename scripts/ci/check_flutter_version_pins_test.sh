#!/bin/bash
#
# Manual test harness for scripts/ci/check_flutter_version_pins.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. Each case builds a
# small repo layout in a temp directory.
#
# Usage:
#   scripts/ci/check_flutter_version_pins_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/check_flutter_version_pins.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

# new_repo <fvmrc version>
#
# Starts a fresh layout with an .fvmrc and a codemagic.yaml that pins nothing.
new_repo() {
  rm -rf "${WORK_DIR}/repo"
  mkdir -p "${WORK_DIR}/repo/.github/workflows"
  printf '{\n  "flutter": "%s"\n}\n' "$1" >"${WORK_DIR}/repo/.fvmrc"
  printf 'workflows:\n  check:\n    environment:\n      groups:\n        - g\n' \
    >"${WORK_DIR}/repo/codemagic.yaml"
}

# add_workflow <file name> <flutter-version line>
add_workflow() {
  printf 'jobs:\n  j:\n    steps:\n      - uses: subosito/flutter-action@v2\n        with:\n          %s\n' \
    "$2" >"${WORK_DIR}/repo/.github/workflows/$1"
}

run_target() {
  OUTPUT="$("$TARGET" "${WORK_DIR}/repo" 2>&1)"
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

new_repo 3.44.4
add_workflow e2e.yml 'flutter-version: "3.44.4"'
add_workflow dash.yaml "flutter-version: '3.44.4'"
run_target
assert_true "passes when every workflow matches .fvmrc" exit_code_is 0

new_repo 3.44.4
run_target
assert_true "passes when no workflow sets a Flutter version" exit_code_is 0

new_repo 3.44.4
add_workflow e2e.yml 'flutter-version: "3.32.0"'
run_target
assert_true "fails when a workflow differs from .fvmrc" exit_code_is 1
assert_true "names the differing workflow and version" output_contains "e2e.yml"
assert_true "shows the version found" output_contains "flutter-version 3.32.0"

new_repo 3.44.4
add_workflow dash.yaml 'flutter-version: 3.44.5'
run_target
assert_true "fails on an unquoted .yaml workflow that differs" exit_code_is 1

new_repo 3.44.4
add_workflow e2e.yml '# flutter-version: "3.32.0"'
run_target
assert_true "ignores a commented-out version" exit_code_is 0

new_repo 3.44.4
printf '      flutter: 3.32.0\n' >>"${WORK_DIR}/repo/codemagic.yaml"
run_target
assert_true "fails when codemagic.yaml pins a version" exit_code_is 1
assert_true "tells the reader the version comes from .fvmrc" output_contains "The version comes from .fvmrc (3.44.4)"

new_repo 3.44.4
printf '      flutter: v3.44.4\n' >>"${WORK_DIR}/repo/codemagic.yaml"
run_target
assert_true "fails on a v-prefixed pin, even one equal to .fvmrc" exit_code_is 1

new_repo 3.44.4
printf '      flutter: stable\n' >>"${WORK_DIR}/repo/codemagic.yaml"
run_target
assert_true "allows a channel name in codemagic.yaml" exit_code_is 0

new_repo 3.44.4
rm "${WORK_DIR}/repo/.fvmrc"
run_target
assert_true "fails when .fvmrc is missing" exit_code_is 1

new_repo 3.44.4
printf '{}\n' >"${WORK_DIR}/repo/.fvmrc"
run_target
assert_true "fails when .fvmrc has no flutter version" exit_code_is 1
assert_true "names the empty .fvmrc" output_contains 'No "flutter" version found'

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
