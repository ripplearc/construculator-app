#!/bin/bash
set -euo pipefail

# Run the unit and widget tests a branch changed, with coverage, and fail when
# a newly added lib/ file has no coverage or the new files fall below target.
# Usage: ./scripts/ci/run_changed_tests_with_coverage.sh [target-branch] [output-dir]
#
# Environment:
#   ARC_CODE_COVERAGE_TARGET  required percentage. Read only when the threshold
#                             check is reached, and a missing value fails.
#   CODE_COVERAGE_MINIMUM     used instead when the last commit message contains
#                             #DeltaCoverageLow or DCL.
#   FLUTTER_CMD               defaults to "fvm flutter".
#
# CA-658: a new lib/ file must be covered by a changed test.
# CA-1033: a change with no lib/ file (for example only scripts/) passes.
# A base commit that cannot be found fails the script. It never means
# "no tests changed".

TARGET_BRANCH="${1:-main}"
OUTPUT_DIR="${2:-coverage/changed}"
FLUTTER_CMD="${FLUTTER_CMD:-fvm flutter}"

fail() {
  echo "❌ $1"
  exit 1
}

find_merge_base() {
  if git merge-base HEAD "origin/$TARGET_BRANCH" 2>/dev/null; then
    return 0
  fi
  if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
    echo "Shallow clone: fetching the full history to find the merge base." >&2
    git fetch --unshallow origin >&2
    git merge-base HEAD "origin/$TARGET_BRANCH"
    return $?
  fi
  return 1
}

without_generated_or_ignored() {
  { grep -v -E '(\.g\.dart$|\.freezed\.dart$|/generated/|/l10n/)' || true; } |
    while IFS= read -r file; do
      head -1 "$file" 2>/dev/null | grep -q '// coverage:ignore-file' || echo "$file"
    done
}

fail_for_zero_coverage() {
  echo "❌ The following new source files have zero coverage (no changed test exercises them):"
  while IFS= read -r file; do
    echo "  - $file"
  done <<< "$1"
  echo "Every new lib/**/*.dart file must be exercised by at least one test."
  exit 1
}

coverage_target() {
  if git log -1 --pretty=%B | grep -Eq '#DeltaCoverageLow|DCL'; then
    : "${CODE_COVERAGE_MINIMUM:?CODE_COVERAGE_MINIMUM is not set}"
    echo "Using minimum coverage target: ${CODE_COVERAGE_MINIMUM}%" >&2
    echo "$CODE_COVERAGE_MINIMUM"
  else
    : "${ARC_CODE_COVERAGE_TARGET:?ARC_CODE_COVERAGE_TARGET is not set}"
    echo "$ARC_CODE_COVERAGE_TARGET"
  fi
}

git fetch origin "$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH" ||
  fail "Could not fetch $TARGET_BRANCH from origin."

BASE_COMMIT=$(find_merge_base) ||
  fail "Could not find a merge base between HEAD and origin/$TARGET_BRANCH. Failing instead of assuming no tests changed."

TEST_DIRS=$(find test/features test/libraries test/app test/tools -type d \
  \( -name "units" -o -name "widgets" \) 2>/dev/null | sort || true)

CHANGED_TESTS=""
if [ -n "$TEST_DIRS" ]; then
  PATTERNS=()
  while IFS= read -r dir; do
    PATTERNS+=("$dir/*.dart")
  done <<< "$TEST_DIRS"
  CHANGED_TESTS=$(git diff --name-only --diff-filter=d "$BASE_COMMIT" HEAD -- "${PATTERNS[@]}")
fi

CHANGED_SOURCE_FILES=$(git diff --name-only --diff-filter=A "$BASE_COMMIT" HEAD -- 'lib/*.dart' |
  without_generated_or_ignored)
CHANGED_LIB_FILES=$(git diff --name-only --diff-filter=d "$BASE_COMMIT" HEAD -- 'lib/*.dart' |
  without_generated_or_ignored)

if [ -z "$CHANGED_TESTS" ]; then
  echo "✅ No test files modified. Skipping test execution..."
  if [ -n "$CHANGED_SOURCE_FILES" ]; then
    fail_for_zero_coverage "$CHANGED_SOURCE_FILES"
  fi
  exit 0
fi

echo "🔍 Running tests for changed files:"
echo "$CHANGED_TESTS"
TESTS=()
while IFS= read -r test_file; do
  TESTS+=("$test_file")
done <<< "$CHANGED_TESTS"

mkdir -p "$OUTPUT_DIR"
# shellcheck disable=SC2086 # FLUTTER_CMD is a command line, split on purpose
$FLUTTER_CMD test "${TESTS[@]}" --coverage --coverage-path "$OUTPUT_DIR/lcov.info" --machine \
  >"$OUTPUT_DIR/flutter.json"

if [ -z "$CHANGED_LIB_FILES" ]; then
  echo "✅ No changed source files in lib/. Skipping coverage threshold check."
  exit 0
fi

command -v lcov >/dev/null || fail "lcov is not installed."
[ -s "$OUTPUT_DIR/lcov.info" ] || fail "Coverage file $OUTPUT_DIR/lcov.info is missing or empty."

lcov --quiet --remove "$OUTPUT_DIR/lcov.info" '**/*.g.dart' '**/*.freezed.dart' '**/l10n/**' \
  -o "$OUTPUT_DIR/lcov.info" --ignore-errors unused,empty

COVERED_SOURCES=$(grep '^SF:' "$OUTPUT_DIR/lcov.info" | cut -d: -f2- || true)
EXTRACT_PATTERNS=()
MISSING_FILES=""
while IFS= read -r file; do
  [ -z "$file" ] && continue
  if printf '%s\n' "$COVERED_SOURCES" | grep -Fxq "$file" ||
    printf '%s\n' "$COVERED_SOURCES" | grep -Fxq "$PWD/$file"; then
    EXTRACT_PATTERNS+=("$file" "*/$file")
  else
    MISSING_FILES="${MISSING_FILES}${file}"$'\n'
  fi
done <<< "$CHANGED_SOURCE_FILES"

if [ -n "$MISSING_FILES" ]; then
  fail_for_zero_coverage "${MISSING_FILES%$'\n'}"
fi

if [ "${#EXTRACT_PATTERNS[@]}" -eq 0 ]; then
  echo "✅ No new source files with coverage records. Skipping coverage threshold check."
  exit 0
fi

lcov --quiet --extract "$OUTPUT_DIR/lcov.info" "${EXTRACT_PATTERNS[@]}" \
  -o "$OUTPUT_DIR/changed.lcov.info" --ignore-errors unused,empty

LINES_FOUND=$(grep '^LF:' "$OUTPUT_DIR/changed.lcov.info" | cut -d: -f2 | awk '{sum+=$1} END {print sum+0}')
LINES_HIT=$(grep '^LH:' "$OUTPUT_DIR/changed.lcov.info" | cut -d: -f2 | awk '{sum+=$1} END {print sum+0}')

if [ "$LINES_FOUND" -eq 0 ]; then
  echo "⚠️ No executable lines in the new source files. Skipping coverage threshold check."
  exit 0
fi

TARGET=$(coverage_target)
COVERAGE_PERCENT=$(awk -v hit="$LINES_HIT" -v found="$LINES_FOUND" 'BEGIN {printf "%.2f", hit * 100 / found}')
echo "Changed source coverage: ${COVERAGE_PERCENT}%"

if awk -v coverage="$COVERAGE_PERCENT" -v target="$TARGET" 'BEGIN {exit !(coverage < target)}'; then
  fail "Coverage is ${COVERAGE_PERCENT}%, below ${TARGET}%"
fi
echo "✅ Coverage is ${COVERAGE_PERCENT}% (>= ${TARGET}%)"
