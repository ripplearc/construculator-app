#!/bin/bash
set -euo pipefail
echo "🔄 Script started at: $(date +'%Y-%m-%d %H:%M:%S %Z')"
# Command options:
# ./run_check.sh --pre: run pre-check only
# ./run_check.sh --comp: run comprehensive check only
# ./run_check.sh --all: run both pre-check and comprehensive check
# ./run_check.sh --mutations: run mutation tests only
# ./run_check.sh --target BRANCH: specify target branch (default: main)

# Configuration
TARGET_BRANCH=${TARGET_BRANCH:-main}
ARC_CODE_COVERAGE_TARGET=${ARC_CODE_COVERAGE_TARGET:-95}

# Functions
check_dependencies() {
  local missing=()
  for cmd in git flutter dart; do
    if ! command -v $cmd &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ "$RUN_MUTATIONS" == true || "$RUN_COMPREHENSIVE" == true ]] && [[ -z "$(command -v lcov)" ]]; then
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
  fvm flutter pub get

  # Get base commit
  git fetch origin "$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH"
  local base_commit=$(git merge-base HEAD "origin/$TARGET_BRANCH")

  # Changed Dart files analysis
  local changed_dart_files=$(git diff --name-only --diff-filter=d "$base_commit" -- "lib/*.dart" "test/*.dart")
  
  if [[ -z "$changed_dart_files" ]]; then
    echo "✅ No Dart files changed"
  else
    echo "🔍 Analyzing changed files..."
    fvm flutter analyze --fatal-infos --fatal-warnings $changed_dart_files
    
    # Filter out generated files (matching analysis_options.yaml exclusions)
    local filtered_files=$(echo "$changed_dart_files" | grep -v -E "(lib/generated/|\.g\.dart$|\.freezed\.dart$|lib/l10n/generated/)")
    
    # Run custom lint on changed files with all rules (excluding generated files)
    if [[ -n "$filtered_files" ]]; then
      echo "🔍 Running custom linter (ripplearc_linter rules) on changed files..."
      local all_rules="prefer_fake_over_mock,forbid_forced_unwrapping,no_optional_operators_in_tests,document_fake_parameters,document_interface,todo_with_story_links,no_internal_method_docs,specific_exception_types,avoid_test_timeouts,private_subject,sealed_over_dynamic"
      dart run ripplearc_linter:standalone_checker --rules $all_rules $filtered_files
    else
      echo "✅ No non-generated Dart files changed, skipping custom linter"
    fi
  fi

  # Changed tests
  local changed_tests=$(git diff --name-only --diff-filter=d "$base_commit" -- "test/*.dart")
  if [[ -z "$changed_tests" ]]; then
    echo "✅ No tests changed"
  else
    echo "🧪 Running changed tests..."
    fvm flutter test $changed_tests --update-goldens --coverage
    lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' -o coverage/lcov.info

    # Process coverage
    if [[ -f "coverage/lcov.info" ||  ! -s "coverage/lcov.info" ]]; then
      lcov --remove coverage/lcov.info '**/*.g.dart' '**/l10n/**' -o coverage/lcov.info
      local lf=$(grep '^LF:' coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
      local lh=$(grep '^LH:' coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
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
  fi
}

run_mutation_tests() {
  echo "🧬 Running mutation tests..."
  local start=$(date +%s)
  echo "⏳ [$(date +'%H:%M:%S')] Starting mutation tests..."
  BASE_COMMIT=$(git merge-base HEAD origin/$TARGET_BRANCH)

  echo "🧬 Checking for changed mutation config files..."
  CHANGED_FILES=$(git diff --name-only --diff-filter=d "$TARGET_BRANCH" -- "test/mutations/*.xml")

  if [ -z "$CHANGED_FILES" ]; then
  echo "✅ No changed mutation config files detected. Skipping mutation tests."
  exit 0
  fi

  echo "Found changed mutation config files:"
  echo "$CHANGED_FILES"

  echo "🧪 Running mutation tests..."
  dart run mutation_test $CHANGED_FILES --no-builtin
  echo "✅ [$(date +'%H:%M:%S')] Mutation tests completed in $((end - start)) seconds"
  return 0
}

comprehensive_check() {
  echo "🚀 Running Comprehensive Check..."

  # Install dependencies
  fvm flutter pub get

  # Full code analysis
  echo "🔍 Full code analysis..."
  fvm flutter analyze --fatal-infos --fatal-warnings .

  # Get base commit for custom linter check on changed files only
  git fetch origin "$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH"
  local base_commit=$(git merge-base HEAD "origin/$TARGET_BRANCH")
  
  # Get committed changed files (compared to base commit) for custom_lint only
  local changed_dart_files=$(git diff --name-only --diff-filter=d "$base_commit" -- "lib/*.dart" "test/*.dart")
  
  # Filter out generated files (matching analysis_options.yaml exclusions)
  local filtered_files=$(echo "$changed_dart_files" | grep -v -E "(lib/generated/|\.g\.dart$|\.freezed\.dart$|lib/l10n/generated/)")
  
  # Run custom linter only on changed files (excluding generated files)
  if [[ -z "$filtered_files" ]]; then
    echo "✅ No non-generated Dart files changed, skipping custom linter"
  else
    echo "🔍 Running custom linter (ripplearc_linter rules) on changed files..."
    local all_rules="prefer_fake_over_mock,forbid_forced_unwrapping,no_optional_operators_in_tests,document_fake_parameters,document_interface,todo_with_story_links,no_internal_method_docs,specific_exception_types,avoid_test_timeouts,private_subject,sealed_over_dynamic"
    dart run ripplearc_linter:standalone_checker --rules $all_rules $filtered_files
  fi

  # Unit tests with coverage
  if [ -d "test/units" ] && [ "$(ls -A test/units)" ]; then
    echo "🧪 Unit tests with coverage..."
    mkdir -p test-results
    fvm flutter test test/units test/widgets --coverage --machine > test-results/flutter.json

    # Process coverage
    if [[ -f "coverage/lcov.info" ||  ! -s "coverage/lcov.info" ]]; then
      lcov --remove coverage/lcov.info '**/*.g.dart' '**/l10n/**' -o coverage/lcov.info
      
      # Show individual file coverage
      echo "📊 Individual file coverage:"
      echo "----------------------------------------"
      grep '^SF:' coverage/lcov.info | while read -r line; do
        local file_path=$(echo "$line" | cut -d: -f2-)
        local file_name=$(basename "$file_path")
        
        # Get coverage for this specific file
        local file_lf=$(grep -A 1000 "^SF:$file_path" coverage/lcov.info | grep '^LF:' | head -1 | cut -d: -f2)
        local file_lh=$(grep -A 1000 "^SF:$file_path" coverage/lcov.info | grep '^LH:' | head -1 | cut -d: -f2)
        
        if [[ -n "$file_lf" && -n "$file_lh" && "$file_lf" -gt 0 ]]; then
          local file_coverage=$(echo "scale=1; $file_lh*100/$file_lf" | bc)
          printf "%-40s %6s%%\n" "$file_name" "$file_coverage"
        fi
      done
      echo "----------------------------------------"
      
      # Calculate overall coverage
      local lf=$(grep '^LF:' coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
      local lh=$(grep '^LH:' coverage/lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum}')
      local coverage=$(echo "scale=2; $lh*100/$lf" | bc)

      echo "📊 Overall Coverage: $coverage% (Target: ${ARC_CODE_COVERAGE_TARGET}%)"
      if (( $(echo "$coverage < $ARC_CODE_COVERAGE_TARGET" | bc -l) )); then
        echo "❌ Low coverage"
        exit 1
      fi
    else
      echo "⚠️ Coverage file missing after running unit tests. This might indicate an issue with test execution or setup."
      # Optionally, decide if this should be an exit 1 or just a warning.
      # For now, it's a warning, as the original script exits.
      # If skipping unit tests is fine, then missing coverage if tests didn't run is also fine.
      # However, if tests RAN and coverage is STILL missing, that's an error.
      exit 1
    fi
  else
    echo "⏩ Skipping unit tests: test/units directory not found."
  fi

  # Screenshot tests
  if [ -d "test/screenshots" ] && [ "$(ls -A test/screenshots)" ]; then
    echo "🖼️ Screenshot tests..."
    fvm flutter test test/screenshots --update-goldens
  else
    echo "⏩ Skipping screenshot tests: test/screenshots directory not found."
  fi

  # Build Android
  echo "🤖 Building Android..."
  # Check if product flavors are configured
  if grep -q "productFlavors" android/app/build.gradle; then
    echo "📱 Product flavors detected. Building for 'fishfood' flavor..."
    fvm flutter build apk --debug --flavor fishfood
    
    # Check for APK in flavor-specific location
    APK_PATH="build/app/outputs/flutter-apk/app-fishfood-debug.apk"
    if [[ -f "$APK_PATH" ]]; then
      echo "✅ APK built successfully: $APK_PATH"
    else
      echo "❌ APK not found at $APK_PATH"
      echo "🔍 Checking other possible locations..."
      find build/app/outputs/flutter-apk -name "*.apk" 2>/dev/null || echo "No APK files found"
      exit 1
    fi
  else
    fvm flutter build apk --flavor fishfood
    
    # Check for default APK
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
    if [[ -f "$APK_PATH" ]]; then
      echo "✅ APK built successfully: $APK_PATH"
    else
      echo "❌ APK not found at $APK_PATH"
      exit 1
    fi
  fi

  if [[ "$(uname)" == "Darwin" ]]; then
    echo "🍏 Building iOS..."
    
    # Ensure iOS artifacts are available
    echo "📦 Pre-caching iOS artifacts..."
    fvm flutter precache --ios
    
    if [[ -d "ios" ]]; then
      cd ios
      pod install
      cd ..
    fi
    fvm flutter build ios --debug --no-codesign
  else
    echo "Skipping iOS build because the system is not macOS."
  fi
}

# Main execution
RUN_PRE=false
RUN_COMPREHENSIVE=false
RUN_MUTATIONS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --pre) RUN_PRE=true ;;
    --comp) RUN_COMPREHENSIVE=true ;;
    --all) RUN_PRE=true; RUN_COMPREHENSIVE=true ;;
    --mutations) RUN_MUTATIONS=true ;;
    --target) TARGET_BRANCH="$2"; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

if ! $RUN_PRE && ! $RUN_COMPREHENSIVE && ! $RUN_MUTATIONS; then
  echo "Usage: $0 [--pre] [--comp] [--all] [--mutations] [--target BRANCH]"
  exit 1
fi

check_dependencies

if $RUN_PRE; then
  pre_check
fi

if $RUN_COMPREHENSIVE; then
  comprehensive_check
fi

if $RUN_MUTATIONS; then
  # Install dependencies if not already done
  if ! $RUN_PRE && ! $RUN_COMPREHENSIVE; then
    fvm flutter pub get
  fi
  
  if ! run_mutation_tests; then
    exit 1
  fi
fi

echo "✅ All checks completed successfully"

echo "🏁 Script completed at: $(date +'%Y-%m-%d %H:%M:%S %Z')"