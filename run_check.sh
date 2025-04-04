#!/bin/bash
set -euo pipefail

# Configuration
TARGET_BRANCH=${TARGET_BRANCH:-master}
ARC_CODE_COVERAGE_TARGET=${ARC_CODE_COVERAGE_TARGET:-90}

# Functions
check_dependencies() {
  local missing=()
  for cmd in git flutter dart; do
    if ! command -v $cmd &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ "$RUN_COMPREHENSIVE" == true && ! -f "/usr/local/bin/lcov" ]]; then
    missing+=("lcov")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing dependencies: ${missing[*]}"
    exit 1
  fi
}

pre_check() {
  echo "🚀 Running Pre-check..."

  # Check for skip ci in commit message
  if git log -1 --pretty=%B | grep -Eqi "\[(skip ci|ci skip)\]"; then
    echo "❌ Error: Commit contains [skip ci]"
    exit 1
  fi

  # Install dependencies
  flutter pub get

  # Get base commit
  git fetch origin "$TARGET_BRANCH"
  local base_commit=$(git merge-base HEAD "origin/$TARGET_BRANCH")

  # Changed Dart files analysis
  local changed_dart_files=$(git diff --name-only "$base_commit" -- "lib/*.dart" "test/*.dart")
  if [[ -z "$changed_dart_files" ]]; then
    echo "✅ No Dart files changed"
  else
    echo "🔍 Analyzing changed files..."
    flutter analyze --fatal-infos --fatal-warnings $changed_dart_files
  fi

  # Changed tests
  local changed_tests=$(git diff --name-only "$base_commit" -- "test/*.dart")
  if [[ -z "$changed_tests" ]]; then
    echo "✅ No tests changed"
  else
    echo "🧪 Running changed tests..."
    flutter test $changed_tests --update-goldens
  fi
}

comprehensive_check() {
  echo "🚀 Running Comprehensive Check..."

  # Install dependencies
  flutter pub get

  # Full code analysis
  echo "🔍 Full code analysis..."
  flutter analyze --fatal-infos --fatal-warnings .

  # Unit tests with coverage
  echo "🧪 Unit tests with coverage..."
  mkdir -p test-results
  flutter test --tags=units --coverage --machine > test-results/flutter.json

  # Process coverage
  if [[ -f "coverage/lcov.info" ]]; then
    local lf=$(grep -m1 '^LF:' coverage/lcov.info | cut -d: -f2)
    local lh=$(grep -m1 '^LH:' coverage/lcov.info | cut -d: -f2)
    local coverage=$(echo "scale=2; $lh*100/$lf" | bc)

    echo "📊 Coverage: $coverage% (Target: ${ARC_CODE_COVERAGE_TARGET}%)"
    if (( $(echo "$coverage < $ARC_CODE_COVERAGE_TARGET" | bc -l) )); then
      echo "❌ Low coverage"
      exit 1
    fi
  else
    echo "❌ Coverage file missing"
    exit 1
  fi

  # Widget tests
  echo "📱 Widget tests..."
  flutter test test/widgets

  # Screenshot tests
  echo "🖼️ Screenshot tests..."
  flutter test test/screenshots --update-goldens

  # Mutation testing
  echo "🧬 Mutation testing..."
  local base_commit=$(git merge-base HEAD "origin/$TARGET_BRANCH")
  local changed_files=$(git diff --name-only "$base_commit" | grep -v "^test/" | grep "\.dart$")

  if [[ -n "$changed_files" ]]; then
    echo "Running mutation tests for:"
    echo "$changed_files"
    dart run mutation_test $changed_files --rules=mutation_test_rules.xml
  else
    echo "✅ No files for mutation testing"
  fi

  # Build Android
  echo "🤖 Building Android..."
  flutter build apk --debug

  # Build iOS
  echo "🍏 Building iOS..."
  if [[ -d "ios" ]]; then
    cd ios
    pod install
    cd ..
  fi
  flutter build ios --debug --no-codesign
}

# Main execution
RUN_PRE=false
RUN_COMPREHENSIVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --pre) RUN_PRE=true ;;
    --comp) RUN_COMPREHENSIVE=true ;;
    --all) RUN_PRE=true; RUN_COMPREHENSIVE=true ;;
    --target) TARGET_BRANCH="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if ! $RUN_PRE && ! $RUN_COMPREHENSIVE; then
  echo "Usage: $0 [--pre] [--comp] [--all] [--target BRANCH]"
  exit 1
fi

check_dependencies

if $RUN_PRE; then
  pre_check
fi

if $RUN_COMPREHENSIVE; then
  comprehensive_check
fi

echo "✅ All checks completed successfully"