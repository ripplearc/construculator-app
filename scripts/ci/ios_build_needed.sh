#!/bin/bash
set -euo pipefail

# Decide whether the Codemagic iOS debug build must run for the checked-out commit.
# Usage: ./scripts/ci/ios_build_needed.sh
#        ./scripts/ci/ios_build_needed.sh --classify <path>
#
# Prints one line on stdout: "run: <reason>" or "skip: <reason>".
# "skip" is printed only when the commit changes at least one file compared with
# the base branch and every changed file is listed as not iOS-related in
# ios_build_paths.conf. A file the list does not mention, an empty diff (for
# example the nightly build on main) and anything else the script cannot
# establish answers "run".
#
# --classify prints "ios", "other" or "unknown" for one path.
#
# Environment:
#   FORCE_IOS_BUILD   "true" always answers "run" (set by #RunCheck ios)
#   BASE_BRANCH       branch to compare with, defaults to main

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATHS_FILE="${IOS_BUILD_PATHS_FILE:-$SCRIPT_DIR/ios_build_paths.conf}"

# Prints "ios", "other" or "unknown", then the matching pattern.
classify() {
  local path="$1" kind pattern
  while read -r kind pattern; do
    case "$kind" in
      ios | other) ;;
      *) continue ;;
    esac
    case "$pattern" in
      */)
        case "$path" in "$pattern"*) echo "$kind $pattern"; return 0 ;; esac
        ;;
      *)
        # shellcheck disable=SC2254 # the pattern is a glob on purpose
        case "$path" in $pattern) echo "$kind $pattern"; return 0 ;; esac
        ;;
    esac
  done < <(grep -E '^(ios|other)[[:space:]]' "$PATHS_FILE")
  echo "unknown"
}

if [ "${1:-}" = "--classify" ]; then
  classify "${2:?--classify needs a path}"
  exit 0
fi

BASE_BRANCH="${BASE_BRANCH:-main}"

run_because() {
  echo "run: $1"
  exit 0
}

if [ "${FORCE_IOS_BUILD:-false}" = "true" ]; then
  run_because "FORCE_IOS_BUILD is true (#RunCheck ios)"
fi

# #RunCheck builds have no pull request destination, so the base is fetched by
# name, as scripts/run_check.sh does.
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  git fetch --quiet --unshallow origin ||
    run_because "could not fetch the full history"
fi
git fetch --quiet origin "$BASE_BRANCH:refs/remotes/origin/$BASE_BRANCH" ||
  run_because "could not fetch $BASE_BRANCH"
MERGE_BASE=$(git merge-base HEAD "origin/$BASE_BRANCH") ||
  run_because "found no common commit with $BASE_BRANCH"
CHANGED_FILES=$(git diff --name-only --no-renames "$MERGE_BASE" HEAD) ||
  run_because "could not list the changed files"

if [ -z "$CHANGED_FILES" ]; then
  run_because "no file differs from $BASE_BRANCH, so there is nothing to classify"
fi

TOTAL=0
while IFS= read -r file; do
  TOTAL=$((TOTAL + 1))
  MATCH=$(classify "$file")
  case "$MATCH" in
    "ios "*) run_because "$file matches ${MATCH#ios }" ;;
    unknown) run_because "$file is not listed in ios_build_paths.conf" ;;
  esac
done <<< "$CHANGED_FILES"

echo "skip: no iOS-related files changed ($TOTAL files checked)"
