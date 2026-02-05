#!/bin/bash
set -euo pipefail

# Run Code Analysis Script
# Usage: ./scripts/ci/run_code_analysis.sh <target_branch> [--pre|--comp]
#   --pre:  Analyze only changed files (for pre-check)
#   --comp: Analyze entire codebase (for comprehensive-check)

TARGET_BRANCH="${1:-main}"
MODE="${2:---pre}"

echo "🛠️ Running Flutter analysis..."
echo "Target branch: $TARGET_BRANCH"
echo "Mode: $MODE"

# Fetch target branch
git fetch origin "$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH"

# Check for rebase conflicts
echo "🔄 Checking for rebase conflicts..."
if ! git rebase --autostash origin/"$TARGET_BRANCH"; then
  echo "❌ Rebase failed due to conflicts!"
  CONFLICTED_FILES=$(git diff --name-only --diff-filter=U 2>/dev/null || git ls-files -u | awk '{print $4}' | sort -u || echo "Unable to determine")
  if [ -n "$CONFLICTED_FILES" ] && [ "$CONFLICTED_FILES" != "Unable to determine" ]; then
    echo "Conflicting files:"
    echo "$CONFLICTED_FILES"
  else
    echo "Unable to determine specific conflicting files, but rebase failed."
  fi
  git rebase --abort
  exit 1
fi
echo "✅ Rebase successful, no conflicts detected"

# After successful rebase, find delta files
BASE_COMMIT=origin/$TARGET_BRANCH
CHANGED_DART_FILES=$(git diff --name-only --diff-filter=d "$BASE_COMMIT" HEAD -- "lib/*.dart" "test/*.dart")

# Run Flutter analysis based on mode
if [ "$MODE" = "--pre" ]; then
  # Pre-check mode: analyze only changed files
  if [ -z "$CHANGED_DART_FILES" ]; then
    echo "✅ No Dart files modified. Skipping analysis."
    exit 0
  fi
  echo "🛠️ Analyzing changed files:"
  echo "$CHANGED_DART_FILES"
  fvm flutter analyze --fatal-infos --fatal-warnings $CHANGED_DART_FILES
else
  # Comprehensive mode: analyze entire codebase
  fvm flutter analyze --fatal-infos --fatal-warnings .
fi

# Filter out generated files (matching analysis_options.yaml exclusions)
FILTERED_FILES=$(echo "$CHANGED_DART_FILES" | grep -v -E "(lib/generated/|\.g\.dart$|\.freezed\.dart$|lib/l10n/generated/)" || true)

# Run custom linter on filtered files
if [ -z "$FILTERED_FILES" ]; then
  echo "✅ No non-generated Dart files changed, skipping custom linter"
else
  echo "🔍 Running custom linter (ripplearc_linter rules) on changed files..."
  ALL_RULES="prefer_fake_over_mock,forbid_forced_unwrapping,no_optional_operators_in_tests,document_fake_parameters,document_interface,todo_with_story_links,no_internal_method_docs,specific_exception_types,avoid_test_timeouts,private_subject,sealed_over_dynamic,avoid_static_colors,avoid_static_typography,no_direct_instantiation"
  fvm dart run ripplearc_linter:standalone_checker --rules $ALL_RULES $FILTERED_FILES
fi

echo "✅ Code analysis completed successfully"

