#!/bin/bash
#
# Manual test harness for scripts/ci/decide_ios_build.sh (CA-1534).
#
# Follows the repo's bash test convention (see assert_flavor_environment_test.sh):
# no shell-test framework, non-zero exit if any case fails. Every case runs the
# script inside a real throwaway git clone of a throwaway "origin". Main holds
# the real ios_build_needed.sh and a small path list of its own, so each case
# can change those two files on the branch and show that only main's copies
# decide.
#
# Usage:
#   scripts/ci/decide_ios_build_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/decide_ios_build.sh"
REAL_DECISION_SCRIPT="${SCRIPT_DIR}/ios_build_needed.sh"
CODEMAGIC_YAML="$(cd "$SCRIPT_DIR/../.." && pwd)/codemagic.yaml"

FAILURES=0

WORK_DIR="$(mktemp -d)"
ORIGIN="${WORK_DIR}/origin.git"
CLONE="${WORK_DIR}/clone"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

git_in() {
  local dir="$1"
  shift
  git -C "$dir" -c user.name=test -c user.email=test@example.org -c commit.gpgsign=false "$@"
}

# commit_files <dir> <message> <path>...   writes each path and commits them
commit_files() {
  local dir="$1" message="$2" path
  shift 2
  for path in "$@"; do
    mkdir -p "$dir/$(dirname "$path")"
    echo "$message" >>"$dir/$path"
  done
  git_in "$dir" add -A >/dev/null
  git_in "$dir" commit -q -m "$message"
}

# reset_repos   a bare origin with main, and a clone on a fresh feature branch
reset_repos() {
  rm -rf "$ORIGIN" "$CLONE" "${WORK_DIR}/seed"
  git init -q --bare -b main "$ORIGIN"
  git init -q -b main "${WORK_DIR}/seed"
  commit_files "${WORK_DIR}/seed" "seed" lib/a.dart ios/Runner/old.swift
  mkdir -p "${WORK_DIR}/seed/scripts/ci"
  cp "$REAL_DECISION_SCRIPT" "${WORK_DIR}/seed/scripts/ci/ios_build_needed.sh"
  printf 'ios ios/\nother lib/\nother scripts/\n' >"${WORK_DIR}/seed/scripts/ci/ios_build_paths.conf"
  git_in "${WORK_DIR}/seed" add -A >/dev/null
  git_in "${WORK_DIR}/seed" commit -q -m "rules"
  git_in "${WORK_DIR}/seed" push -q "$ORIGIN" main
  git clone -q "$ORIGIN" "$CLONE"
  git_in "$CLONE" checkout -q -b feature
}

run_target() {
  STDOUT_TEXT="$(cd "$CLONE" && "$TARGET" 2>&1)"
  EXIT_CODE=$?
}

assert_true() {
  local description="$1"
  shift
  if "$@"; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   output: ${STDOUT_TEXT}"
    FAILURES=$((FAILURES + 1))
  fi
}

starts_with() { case "$STDOUT_TEXT" in "$1"*) return 0 ;; esac; return 1; }
contains() { echo "$STDOUT_TEXT" | grep -Fq -- "$1"; }
exit_code_is() { [ "$EXIT_CODE" -eq "$1" ]; }
one_line() { [ "$(echo "$STDOUT_TEXT" | wc -l | tr -d ' ')" -eq 1 ]; }

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
run_target
assert_true "skips a change main's list calls not iOS-related" starts_with "skip:"
assert_true "prints only the answer" one_line
assert_true "exits 0" exit_code_is 0

reset_repos
commit_files "$CLONE" "ios" lib/a.dart ios/Runner/new.swift
run_target
assert_true "runs iOS when an iOS file changes" starts_with "run: ios/Runner/new.swift matches ios/"

reset_repos
printf 'other ios/\nother lib/\nother scripts/\n' >"${CLONE}/scripts/ci/ios_build_paths.conf"
commit_files "$CLONE" "loosen the list" ios/Runner/new.swift
run_target
assert_true "a branch cannot loosen the path list" starts_with "run: ios/Runner/new.swift matches ios/"

reset_repos
printf '#!/bin/bash\necho "skip: always"\n' >"${CLONE}/scripts/ci/ios_build_needed.sh"
commit_files "$CLONE" "always skip" ios/Runner/new.swift
run_target
assert_true "a branch cannot replace the decision script" starts_with "run: ios/Runner/new.swift matches ios/"

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
FORCE_IOS_BUILD=true run_target
assert_true "runs iOS when FORCE_IOS_BUILD is true" contains "FORCE_IOS_BUILD is true"

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
git_in "$CLONE" remote set-url origin "${WORK_DIR}/missing.git"
run_target
assert_true "runs iOS when main cannot be fetched" contains "run: could not fetch main to read the rules"
assert_true "still exits 0 when main cannot be fetched" exit_code_is 0

reset_repos
git_in "${WORK_DIR}/seed" rm -q scripts/ci/ios_build_paths.conf
git_in "${WORK_DIR}/seed" commit -q -m "drop the list"
git_in "${WORK_DIR}/seed" push -q "$ORIGIN" main
commit_files "$CLONE" "dart" lib/a.dart
run_target
assert_true "runs iOS when main has no path list" contains "run: could not read scripts/ci/ios_build_paths.conf from main"
assert_true "still exits 0 when main has no path list" exit_code_is 0

reset_repos
printf '#!/bin/bash\nexit 3\n' >"${WORK_DIR}/seed/scripts/ci/ios_build_needed.sh"
git_in "${WORK_DIR}/seed" commit -q -am "broken script"
git_in "${WORK_DIR}/seed" push -q "$ORIGIN" main
commit_files "$CLONE" "dart" lib/a.dart
run_target
assert_true "runs iOS when the decision script on main fails" starts_with "run: the decision script on main failed"

reset_repos
printf '#!/bin/bash\necho "maybe"\n' >"${WORK_DIR}/seed/scripts/ci/ios_build_needed.sh"
git_in "${WORK_DIR}/seed" commit -q -am "odd script"
git_in "${WORK_DIR}/seed" push -q "$ORIGIN" main
commit_files "$CLONE" "dart" lib/a.dart
run_target
assert_true "runs iOS when the decision script on main gives an unknown answer" starts_with "run: the decision script on main gave no answer (maybe)"

# workflow_block <workflow id>   the lines of one workflow in codemagic.yaml
workflow_block() {
  awk -v id="  $1:" '
    $0 == id { inside = 1; next }
    inside && /^  [a-z][a-z-]*:$/ { exit }
    inside { print }
  ' "$CODEMAGIC_YAML"
}
first_step_script() {
  workflow_block "$1" | awk '/^      - name:/ { seen++ } seen == 1 { print }'
}
STDOUT_TEXT="(codemagic.yaml)"
assert_true "the Pre-check decides in its first step, with the rules on main, and keeps the answer in a file" \
  bash -c "$(declare -f workflow_block first_step_script); CODEMAGIC_YAML='$CODEMAGIC_YAML'; first_step_script pre-check | grep -F 'scripts/ci/decide_ios_build.sh' | grep -Fq 'ios_build_decision.txt'"
assert_true "the Pre-check builds iOS in its last step, reading the same file" \
  bash -c "$(declare -f workflow_block); CODEMAGIC_YAML='$CODEMAGIC_YAML'; workflow_block pre-check | grep -F -- '- name:' | tail -n 1 | grep -Fq 'Build iOS when needed' && workflow_block pre-check | grep -F 'build_ios_when_needed.sh' | grep -Fq 'ios_build_decision.txt'"
assert_true "the Pre-check sets a build time limit" \
  bash -c "$(declare -f workflow_block); CODEMAGIC_YAML='$CODEMAGIC_YAML'; workflow_block pre-check | grep -Eq '^    max_build_duration: [0-9]+$'"
assert_true "the Pre-check takes the API token from its own group" \
  bash -c "$(declare -f workflow_block); CODEMAGIC_YAML='$CODEMAGIC_YAML'; workflow_block pre-check | grep -Fq -- '- codemagic_api'"
assert_true "only the Pre-check uses that group" \
  bash -c "[ \"\$(grep -c -- '- codemagic_api' '$CODEMAGIC_YAML')\" = 1 ]"
assert_true "the iOS workflow does not decide for itself" \
  bash -c "$(declare -f workflow_block); CODEMAGIC_YAML='$CODEMAGIC_YAML'; ! workflow_block ios-debug-build | grep -Eq 'ios_build_needed|IOS_BUILD_DECISION'"

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
