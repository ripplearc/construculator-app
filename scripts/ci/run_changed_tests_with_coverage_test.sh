#!/bin/bash
#
# Manual test harness for scripts/ci/run_changed_tests_with_coverage.sh (CA-1240).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. Every case builds a
# bare "origin" repo and a working clone in a temp directory, so the script's
# real git logic runs. flutter is replaced by a fake that records which test
# files it was given and writes a coverage file from FAKE_* variables. lcov is
# the real one.
#
# Usage:
#   scripts/ci/run_changed_tests_with_coverage_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/run_changed_tests_with_coverage.sh"

FAILURES=0

WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if ! command -v lcov >/dev/null; then
  echo "❌ lcov is required to run this test."
  exit 1
fi

export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

# The fake records each test file it receives in $FAKE_DIR/tests_run and writes
# the coverage file named by --coverage-path. For every path in
# FAKE_LCOV_FILES it writes FAKE_LF lines, of which FAKE_LH are hit. It exits
# with FAKE_EXIT (default 0). FAKE_SF_ABSOLUTE=true writes absolute SF paths.
cat >"${WORK_DIR}/fake_flutter" <<'EOF'
#!/bin/bash
shift
coverage_path=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --coverage-path) coverage_path="$2"; shift ;;
    --*) ;;
    *) echo "$1" >>"$FAKE_DIR/tests_run" ;;
  esac
  shift
done
if [ -n "$coverage_path" ]; then
  : >"$coverage_path"
  for file in ${FAKE_LCOV_FILES:-}; do
    sf="$file"
    [ "${FAKE_SF_ABSOLUTE:-false}" = "true" ] && sf="$PWD/$file"
    {
      echo "TN:"
      echo "SF:$sf"
      i=1
      while [ "$i" -le "${FAKE_LF:-10}" ]; do
        if [ "$i" -le "${FAKE_LH:-10}" ]; then echo "DA:$i,1"; else echo "DA:$i,0"; fi
        i=$((i + 1))
      done
      echo "end_of_record"
    } >>"$coverage_path"
  done
fi
echo '{"success":true}'
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "${WORK_DIR}/fake_flutter"

commit_all() {
  git add -A >/dev/null && git commit -q -m "$1"
}

# new_repo
#
# origin/main has one lib file, one unit test and one script. The working clone
# is on branch "feature", which starts at main.
new_repo() {
  rm -rf "${WORK_DIR}/origin.git" "${WORK_DIR}/seed" "${WORK_DIR}/work" "${WORK_DIR}/fake"
  mkdir -p "${WORK_DIR}/fake"
  git init -q --bare -b main "${WORK_DIR}/origin.git"
  git clone -q "${WORK_DIR}/origin.git" "${WORK_DIR}/seed" 2>/dev/null
  (
    cd "${WORK_DIR}/seed" || exit 1
    git checkout -q -b main
    mkdir -p lib test/features/x/units scripts test/utils
    seq 1 12 >lib/existing.dart
    seq 1 12 >lib/other.dart
    echo "void main() {}" >test/features/x/units/existing_test.dart
    echo "echo old" >scripts/old.sh
    commit_all "main"
    git push -q origin main
  )
  git clone -q "${WORK_DIR}/origin.git" "${WORK_DIR}/work" 2>/dev/null
  git -C "${WORK_DIR}/work" checkout -q -b feature
}

# in_work <command...>  runs in the working clone
in_work() {
  (cd "${WORK_DIR}/work" && "$@")
}

# run_target [args...]
#
# Sets OUTPUT and EXIT_CODE. Pass FAKE_* and coverage variables in the caller.
run_target() {
  OUTPUT="$(
    cd "${WORK_DIR}/work" &&
      FLUTTER_CMD="${WORK_DIR}/fake_flutter" \
      FAKE_DIR="${WORK_DIR}/fake" \
      "$TARGET" "$@" 2>&1
  )"
  EXIT_CODE=$?
}

tests_run() { cat "${WORK_DIR}/fake/tests_run" 2>/dev/null; }

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
tests_run_contains() { tests_run | grep -Fxq -- "$1"; }
no_tests_run() { [ ! -s "${WORK_DIR}/fake/tests_run" ]; }

export ARC_CODE_COVERAGE_TARGET=95
export CODE_COVERAGE_MINIMUM=50

new_repo
in_work git remote remove origin
run_target main
assert_true "fails when the base branch cannot be fetched" exit_code_is 1
assert_true "says it could not fetch the base" output_contains "Could not fetch main"

new_repo
in_work bash -c 'echo "void main() { }" >test/features/x/units/existing_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="" run_target main
assert_true "runs a changed test file" exit_code_is 0
assert_true "passes the changed test to flutter" tests_run_contains "test/features/x/units/existing_test.dart"
assert_true "skips the threshold when no lib file changed" output_contains "No changed source files in lib/"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/f/new.dart" FAKE_LF=10 FAKE_LH=10 run_target main
assert_true "passes a new lib file covered by its test" exit_code_is 0
assert_true "reports full coverage" output_contains "Coverage is 100.00% (>= 95%)"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/f/new.dart" FAKE_SF_ABSOLUTE=true FAKE_LF=10 FAKE_LH=10 run_target main
assert_true "accepts absolute SF paths" exit_code_is 0

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/existing.dart" run_target main
assert_true "fails when a new lib file is absent from the coverage file" exit_code_is 1
assert_true "names the uncovered file" output_contains "- lib/f/new.dart"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; git add -A; git commit -q -m t'
run_target main
assert_true "fails when a new lib file comes with no changed test" exit_code_is 1
assert_true "names the file with zero coverage" output_contains "- lib/f/new.dart"
assert_true "runs no tests when none changed" no_tests_run

new_repo
in_work bash -c 'echo "echo new" >scripts/new.sh; git add -A; git commit -q -m t'
run_target main
assert_true "passes a change that touches only scripts/" exit_code_is 0
assert_true "says no test files changed" output_contains "No test files modified"

new_repo
in_work bash -c 'mkdir -p lib/f; printf "// coverage:ignore-file\nint b() => 2;\n" >lib/f/new.dart; git add -A; git commit -q -m t'
run_target main
assert_true "ignores a new file marked coverage:ignore-file" exit_code_is 0

new_repo
in_work bash -c 'mkdir -p lib/f; echo "int b() => 2;" >lib/f/new.g.dart; echo "int c() => 3;" >lib/f/new.freezed.dart; git add -A; git commit -q -m t'
run_target main
assert_true "ignores new generated files" exit_code_is 0

new_repo
in_work bash -c 'echo "void main() { }" >test/utils/helper_test.dart; git add -A; git commit -q -m t'
run_target main
assert_true "does not run a test outside the units and widgets folders" no_tests_run

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/f/new.dart" FAKE_LF=10 FAKE_LH=5 run_target main
assert_true "fails below the coverage target" exit_code_is 1
assert_true "reports the measured and required percentage" output_contains "Coverage is 50.00%, below 95%"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m "tweak #DeltaCoverageLow"'
FAKE_LCOV_FILES="lib/f/new.dart" FAKE_LF=10 FAKE_LH=5 run_target main
assert_true "uses the minimum target when the commit says #DeltaCoverageLow" exit_code_is 0
assert_true "announces the minimum target" output_contains "Using minimum coverage target: 50%"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
(unset ARC_CODE_COVERAGE_TARGET; FAKE_LCOV_FILES="lib/f/new.dart" run_target main; echo "$EXIT_CODE" >"${WORK_DIR}/code"; echo "$OUTPUT" >"${WORK_DIR}/out")
EXIT_CODE=$(cat "${WORK_DIR}/code")
OUTPUT=$(cat "${WORK_DIR}/out")
assert_true "fails when the coverage target variable is not set" exit_code_is 1
assert_true "names the missing variable" output_contains "ARC_CODE_COVERAGE_TARGET is not set"

new_repo
in_work bash -c 'git checkout -q --orphan unrelated; git rm -rq --cached .; echo "void main() { }" >test/features/x/units/other_test.dart; git add test/features/x/units/other_test.dart; git commit -q -m t'
run_target main
assert_true "fails when no merge base exists instead of assuming no tests changed" exit_code_is 1
assert_true "explains the missing merge base" output_contains "Could not find a merge base"
assert_true "runs no tests when the base is unknown" no_tests_run

new_repo
in_work bash -c 'echo "// edited" >>lib/existing.dart; echo "void main() { }" >test/features/x/units/existing_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/other.dart" run_target main
assert_true "does not demand coverage for a modified lib file that is not new" exit_code_is 0

new_repo
in_work bash -c 'echo "// edited" >>lib/existing.dart; echo "void main() { }" >test/features/x/units/existing_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="" run_target main
assert_true "fails when a modified lib file leaves the coverage file empty" exit_code_is 1
assert_true "names the empty coverage file" output_contains "is missing or empty"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="lib/f/new.dart" FAKE_LF=20 FAKE_LH=19 run_target main
assert_true "passes at exactly the coverage target" exit_code_is 0
assert_true "reports the boundary value" output_contains "Coverage is 95.00% (>= 95%)"

new_repo
in_work bash -c 'echo "void main() { }" >test/features/x/units/existing_test.dart; git add -A; git commit -q -m t'
FAKE_EXIT=1 run_target main
assert_true "fails when a changed test fails" exit_code_is 1

new_repo
in_work bash -c 'echo "void main() { }" >test/features/x/units/existing_test.dart; git add -A; git commit -q -m t'
FAKE_LCOV_FILES="" run_target main "${WORK_DIR}/out_dir"
assert_true "writes the test report to the output directory" test -s "${WORK_DIR}/out_dir/flutter.json"

new_repo
in_work bash -c 'mkdir -p lib/f; seq 1 12 >lib/f/new.dart; echo "void main() { }" >test/features/x/units/new_test.dart; git add -A; git commit -q -m t'
rm -rf "${WORK_DIR}/shallow"
git clone -q --depth 1 --branch feature "file://${WORK_DIR}/origin.git" "${WORK_DIR}/shallow" 2>/dev/null
git -C "${WORK_DIR}/work" push -q origin feature
rm -rf "${WORK_DIR}/shallow"
git clone -q --depth 1 --branch feature "file://${WORK_DIR}/origin.git" "${WORK_DIR}/shallow" 2>/dev/null
OUTPUT="$(
  cd "${WORK_DIR}/shallow" &&
    FLUTTER_CMD="${WORK_DIR}/fake_flutter" FAKE_DIR="${WORK_DIR}/fake" \
      FAKE_LCOV_FILES="lib/f/new.dart" "$TARGET" main 2>&1
)"
EXIT_CODE=$?
assert_true "finds the merge base in a shallow clone" exit_code_is 0
assert_true "fetches the full history first" output_contains "Shallow clone"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
