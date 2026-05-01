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

check_rebase_conflicts() {
  local target_branch="$1"
  
  echo "🔄 Checking for rebase conflicts..."
  if ! git rebase --autostash origin/"$target_branch"; then
    echo "❌ Rebase failed due to conflicts!"
    local conflicted_files=$(git diff --name-only --diff-filter=U 2>/dev/null || git ls-files -u | awk '{print $4}' | sort -u || echo "Unable to determine")
    if [[ -n "$conflicted_files" && "$conflicted_files" != "Unable to determine" ]]; then
      echo "Conflicting files:"
      echo "$conflicted_files"
    else
      echo "Unable to determine specific conflicting files, but rebase failed."
    fi
    git rebase --abort
    return 1
  fi
  echo "✅ Rebase successful, no conflicts detected"
  return 0
}

run_custom_linter() {
  local files="$1"
  
  if [[ -z "$files" ]]; then
    echo "✅ No non-generated Dart files changed, skipping custom linter"
    return 0
  fi
  
  echo "🔍 Running custom linter (ripplearc_linter rules) on changed files..."
  local all_rules="prefer_fake_over_mock,forbid_forced_unwrapping,no_optional_operators_in_tests,document_fake_parameters,document_interface,todo_with_story_links,no_internal_method_docs,specific_exception_types,avoid_test_timeouts,private_subject,sealed_over_dynamic,avoid_static_colors,avoid_static_typography,no_direct_instantiation"
  fvm dart run ripplearc_linter:standalone_checker --rules $all_rules $files
}

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

filter_coverage_tracefile() {
  local tracefile="$1"

  lcov --quiet --remove \
    "$tracefile" \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/l10n/**' \
    -o "$tracefile" \
    --ignore-errors unused
}

build_extract_patterns_from_tracefile() {
  local tracefile="$1"
  local changed_files="$2"

  local covered_sources
  covered_sources=$(grep '^SF:' "$tracefile" | cut -d: -f2- || true)

  local file
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if printf '%s\n' "$covered_sources" | grep -Fxq "$file" || printf '%s\n' "$covered_sources" | grep -Fxq "$PWD/$file"; then
      printf '*/%s\n' "$file"
    fi
  done <<< "$changed_files"
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
  
  # Check for rebase conflicts before running analysis
  if ! check_rebase_conflicts "$TARGET_BRANCH"; then
    exit 1
  fi
  
  # After successful rebase, find delta files from rebased HEAD
  local base_commit=origin/$TARGET_BRANCH

  # Changed Dart files analysis
  local changed_dart_files=$(git diff --name-only --diff-filter=d "$base_commit" HEAD -- "lib/*.dart" "test/*.dart")
  
  if [[ -z "$changed_dart_files" ]]; then
    echo "✅ No Dart files changed"
  else
    echo "🔍 Analyzing changed files..."
    fvm flutter analyze --fatal-infos --fatal-warnings $changed_dart_files
    
    # Filter out generated files and run custom linter
    local filtered_files=$(echo "$changed_dart_files" | grep -v -E "(lib/generated/|\.g\.dart$|\.freezed\.dart$|lib/l10n/generated/)")
    run_custom_linter "$filtered_files"
  fi

  # Changed tests
  local test_dirs=()
  while IFS= read -r dir; do
    [[ -n "$dir" ]] && test_dirs+=("$dir")
  done < <(find test/features test/libraries test/app -type d \
    \( -name "units" -o -name "widgets" \) 2>/dev/null | sort)

  local changed_tests=""
  if [[ ${#test_dirs[@]} -gt 0 ]]; then
    local patterns=()
    for dir in "${test_dirs[@]}"; do
      patterns+=("$dir/*.dart")
    done
    changed_tests=$(git diff --name-only --diff-filter=d "$base_commit" -- "${patterns[@]}")
  fi

  if [[ -z "$changed_tests" ]]; then
    echo "✅ No tests changed"
  else
    echo "🧪 Running changed tests..."
    fvm flutter test $changed_tests --update-goldens --coverage

    # Process coverage
    if [[ -s "coverage/lcov.info" ]]; then
      filter_coverage_tracefile "coverage/lcov.info"

      local changed_source_files
      changed_source_files=$(git diff --name-only --diff-filter=d "$base_commit" HEAD -- 'lib/**/*.dart' | grep -v -E '(\.g\.dart$|\.freezed\.dart$|/generated/|/l10n/)' || true)

      if [[ -z "$changed_source_files" ]]; then
        echo "✅ No changed source files in lib/. Skipping coverage threshold check for --pre."
      else
        local extract_patterns=()
        while IFS= read -r file; do
          [[ -n "$file" ]] && extract_patterns+=("$file")
        done < <(build_extract_patterns_from_tracefile "coverage/lcov.info" "$changed_source_files")

        if [[ ${#extract_patterns[@]} -eq 0 ]]; then
          echo "✅ No changed source files with coverage records. Skipping coverage threshold check."
        else
          lcov --quiet --extract coverage/lcov.info "${extract_patterns[@]}" -o coverage/changed.lcov.info --ignore-errors unused,empty

          local lf=0
          local lh=0
          if [[ -s "coverage/changed.lcov.info" ]]; then
            lf=$(grep '^LF:' coverage/changed.lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum+0}')
            lh=$(grep '^LH:' coverage/changed.lcov.info | cut -d: -f2 | awk '{sum+=$1} END {print sum+0}')
          fi

          if [[ "$lf" -eq 0 ]]; then
            echo "⚠️ No valid coverage records found for changed source files. Skipping coverage threshold check."
          else
            local coverage
            coverage=$(echo "scale=2; $lh*100/$lf" | bc)
            echo "📊 Changed source coverage: $coverage% (Target: ${ARC_CODE_COVERAGE_TARGET}%)"
            if (( $(echo "$coverage < $ARC_CODE_COVERAGE_TARGET" | bc -l) )); then
              echo "❌ Low coverage"
              exit 1
            fi
          fi
        fi
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
  CHANGED_FILES=$(git diff --name-only --diff-filter=d "$TARGET_BRANCH" -- \
    "test/features/**/mutations/*.xml" \
    "test/libraries/**/mutations/*.xml")

  if [ -z "$CHANGED_FILES" ]; then
  echo "✅ No changed mutation config files detected (checked test/features/**/mutations, test/libraries/**/mutations). Skipping mutation tests."
  exit 0
  fi

  echo "Found changed mutation config files:"
  echo "$CHANGED_FILES"

  echo "🧪 Running mutation tests..."
  dart run mutation_test $CHANGED_FILES --no-builtin
  local end=$(date +%s)
  echo "✅ [$(date +'%H:%M:%S')] Mutation tests completed in $((end - start)) seconds"
  return 0
}

comprehensive_check() {
  echo "🚀 Running Comprehensive Check..."

  # Install dependencies
  fvm flutter pub get

  # Get base commit for custom linter check on changed files only
  git fetch origin "$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH"
  
  # Check for rebase conflicts before running analysis
  if ! check_rebase_conflicts "$TARGET_BRANCH"; then
    exit 1
  fi
  
  echo "🔍 Full code analysis..."
  fvm flutter analyze --fatal-infos --fatal-warnings .

  # After successful rebase, find delta files from rebased HEAD
  local base_commit=origin/$TARGET_BRANCH
  
  # Get committed changed files (compared to base commit) for custom_lint only
  local changed_dart_files=$(git diff --name-only --diff-filter=d "$base_commit" HEAD -- "lib/*.dart" "test/*.dart")
  
  # Filter out generated files and run custom linter
  local filtered_files=$(echo "$changed_dart_files" | grep -v -E "(lib/generated/|\.g\.dart$|\.freezed\.dart$|lib/l10n/generated/)")
  run_custom_linter "$filtered_files"

  local unit_test_dirs=()
  while IFS= read -r dir; do
    [[ -n "$dir" ]] && unit_test_dirs+=("$dir")
  done < <(
    find test/features test/libraries test/app -type d \
      \( -name "units" -o -name "widgets" \) 2>/dev/null | sort
  )

  if [[ ${#unit_test_dirs[@]} -gt 0 ]]; then
    echo "🧪 Unit tests with coverage..."
    mkdir -p test-results
    fvm flutter test "${unit_test_dirs[@]}" --coverage --machine > test-results/flutter.json

    # Process coverage
    if [[ -s "coverage/lcov.info" ]]; then
      filter_coverage_tracefile "coverage/lcov.info"
      
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
      exit 1
    fi
  else
    echo "⏩ Skipping unit tests: no test directories found."
  fi

  # Screenshot tests
  local screenshot_test_dirs=()
  while IFS= read -r dir; do
    [[ -n "$dir" ]] && screenshot_test_dirs+=("$dir")
  done < <(find test/features -type d -name "screenshots" 2>/dev/null | sort)

  if [[ ${#screenshot_test_dirs[@]} -gt 0 ]]; then
    echo "🖼️ Screenshot tests..."
    fvm flutter test "${screenshot_test_dirs[@]}" --update-goldens
  else
    echo "⏩ Skipping screenshot tests: no screenshot test files found."
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
