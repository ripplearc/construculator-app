#!/bin/bash
#
# Manual test harness for scripts/ci/ios_build_needed.sh (CA-1240, CA-1346).
#
# Follows the repo's bash test convention (see resolve_build_features_test.sh):
# no shell-test framework, non-zero exit if any case fails. Every case runs the
# script inside a real throwaway git clone of a throwaway "origin". The last
# cases run against the real repository: every top-level path must be
# classified in ios_build_paths.conf, so a new top-level directory cannot
# silently skip the iOS build.
#
# Usage:
#   scripts/ci/ios_build_needed_test.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="${SCRIPT_DIR}/ios_build_needed.sh"

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

reset_repos
commit_files "$CLONE" "dart" lib/a.dart test/a_test.dart docs/x.md scripts/run_check.sh
run_target
assert_true "skips a Dart, test, docs and script change" starts_with "skip:"
assert_true "counts the files it checked" contains "4 files checked"
assert_true "exits 0" exit_code_is 0

for ios_file in ios/Podfile pubspec.yaml pubspec.lock pubspec_overrides.yaml .fvmrc codemagic.yaml \
  .github/workflows/run_c_check.yml assets/env/.env.dev config/flavors/fishfood.json \
  scripts/ci/generate_env_file.sh l10n.yaml build.yaml flutter_launcher_icons-prod.yaml; do
  reset_repos
  commit_files "$CLONE" "ios" lib/a.dart "$ios_file"
  run_target
  assert_true "runs iOS when $ios_file changes" starts_with "run: $ios_file matches"
done

reset_repos
commit_files "$CLONE" "other" .github/workflows/e2e_cuj.yml scripts/perf/x.sh scripts/dashboard/y.dart android/app/build.gradle
run_target
assert_true "skips other workflows, scripts/perf, scripts/dashboard and android/" starts_with "skip:"

reset_repos
mkdir -p "$CLONE/lib"
git_in "$CLONE" mv ios/Runner/old.swift lib/moved.swift
git_in "$CLONE" commit -q -m "move out of ios"
run_target
assert_true "runs iOS when a file was renamed out of ios/" contains "ios/Runner/old.swift matches ios/"

reset_repos
git_in "$CLONE" rm -q lib/a.dart
git_in "$CLONE" commit -q -m "delete"
run_target
assert_true "skips when only a Dart file was deleted" starts_with "skip:"

reset_repos
git_in "$CLONE" rm -q ios/Runner/old.swift
git_in "$CLONE" commit -q -m "delete ios file"
run_target
assert_true "runs iOS when an iOS file was deleted" contains "ios/Runner/old.swift matches ios/"

reset_repos
commit_files "$CLONE" "unlisted" lib/a.dart brand_new_dir/file.txt
run_target
assert_true "runs iOS for a file the list does not mention" contains "not listed in ios_build_paths.conf"

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
FORCE_IOS_BUILD=true run_target
assert_true "runs iOS when FORCE_IOS_BUILD is true" contains "FORCE_IOS_BUILD is true"

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
FORCE_IOS_BUILD=false run_target
assert_true "skips when FORCE_IOS_BUILD is false" starts_with "skip:"

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
FORCE_IOS_BUILD=1 run_target
assert_true "does not read FORCE_IOS_BUILD=1 as true" starts_with "skip:"

reset_repos
git_in "$CLONE" checkout -q main
run_target
assert_true "runs iOS when the commit equals the base, as in the nightly build" contains "no file differs from main"

reset_repos
git_in "$CLONE" checkout -q --orphan unrelated
commit_files "$CLONE" "orphan" lib/a.dart
run_target
assert_true "runs iOS when the branch shares no commit with main" contains "found no common commit"
assert_true "still exits 0 when there is no common commit" exit_code_is 0

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
git_in "$CLONE" remote set-url origin "${WORK_DIR}/missing.git"
run_target
assert_true "runs iOS when main cannot be fetched" contains "could not fetch main"
assert_true "still exits 0 when main cannot be fetched" exit_code_is 0

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
git_in "$CLONE" push -q origin feature
rm -rf "${WORK_DIR}/shallow"
git clone -q --depth 1 --branch feature "file://$ORIGIN" "${WORK_DIR}/shallow"
STDOUT_TEXT="$(cd "${WORK_DIR}/shallow" && "$TARGET" 2>&1)"
EXIT_CODE=$?
assert_true "skips from a shallow clone after fetching the history" starts_with "skip:"

rm -rf "${WORK_DIR}/shallow"
git clone -q --depth 1 --branch feature "file://$ORIGIN" "${WORK_DIR}/shallow"
git_in "${WORK_DIR}/shallow" remote set-url origin "${WORK_DIR}/missing.git"
STDOUT_TEXT="$(cd "${WORK_DIR}/shallow" && "$TARGET" 2>&1)"
EXIT_CODE=$?
assert_true "runs iOS when a shallow clone cannot fetch the history" contains "could not fetch the full history"
assert_true "still exits 0 when the history cannot be fetched" exit_code_is 0

reset_repos
commit_files "$CLONE" "dart" lib/a.dart
git_in "${WORK_DIR}/seed" checkout -q main
commit_files "${WORK_DIR}/seed" "main moved on" ios/Podfile
git_in "${WORK_DIR}/seed" push -q "$ORIGIN" main
run_target
assert_true "ignores an iOS change that landed on main after the branch started" starts_with "skip:"

reset_repos
commit_files "$CLONE" "ios" ios/Podfile
git_in "$CLONE" push -q origin feature:release
git_in "$CLONE" checkout -q -b topic
commit_files "$CLONE" "dart" lib/b.dart
run_target
assert_true "compares with main by default" contains "ios/Podfile matches ios/"
BASE_BRANCH=release run_target
assert_true "compares with BASE_BRANCH when it is set" starts_with "skip:"

# Classification against the real repository
for entry in $(cd "$REPO_ROOT" && git ls-tree --name-only HEAD); do
  [ -d "$REPO_ROOT/$entry" ] && entry="$entry/"
  STDOUT_TEXT="$("$TARGET" --classify "$entry" 2>&1)"
  assert_true "classifies the top-level path $entry" bash -c "[ '$STDOUT_TEXT' != unknown ]"
done

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ ${FAILURES} case(s) failed"
  exit 1
fi
echo "✅ All cases passed"
