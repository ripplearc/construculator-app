#!/bin/bash
set -uo pipefail

# Decide whether the iOS debug build is needed, with the rules on origin/main
# instead of the rules in the checked-out commit, so a pull request cannot
# loosen the path list or the decision script for its own files. This script and
# the Pre-check step that calls it still run from the checked-out commit.
# Usage: ./scripts/ci/decide_ios_build.sh
#
# Copies ios_build_needed.sh and ios_build_paths.conf from origin/main into a
# temporary directory and runs that copy on the checked-out commit. Prints one
# line on stdout, "run: <reason>" or "skip: <reason>", and exits 0. Anything
# that goes wrong answers "run".
#
# Environment:
#   FORCE_IOS_BUILD   "true" always answers "run" (set by #RunCheck ios)

run_because() {
  echo "run: $1"
  exit 0
}

RULES_DIR=$(mktemp -d) || run_because "could not create a temporary directory"
trap 'rm -rf "$RULES_DIR"' EXIT

git fetch --quiet origin main:refs/remotes/origin/main ||
  run_because "could not fetch main to read the rules from it"
for rules_file in ios_build_needed.sh ios_build_paths.conf; do
  git show "origin/main:scripts/ci/$rules_file" > "$RULES_DIR/$rules_file" ||
    run_because "could not read scripts/ci/$rules_file from main"
done

DECISION=$(bash "$RULES_DIR/ios_build_needed.sh") ||
  run_because "the decision script on main failed"

case "$DECISION" in
  "run: "* | "skip: "*) echo "$DECISION" ;;
  *) run_because "the decision script on main gave no answer ($DECISION)" ;;
esac
