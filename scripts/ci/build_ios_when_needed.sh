#!/bin/bash
set -uo pipefail

# Last step of the Pre-check: build iOS unless the first step decided to skip it.
# Usage: ./scripts/ci/build_ios_when_needed.sh <branch> <decision-file>
#
# <decision-file> holds the line decide_ios_build.sh printed. Only a line that
# starts with "skip:" skips. A missing, empty or unreadable file, and any other
# text, starts the Mac build and waits for it (start_ios_build_and_wait.sh), so
# the decision cannot come from anywhere but that file.
#
# Environment:
#   CODEMAGIC_API_TOKEN   required when the build runs
#   CODEMAGIC_APP_ID      the Codemagic app id; CM_PROJECT_ID is used when it is empty

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <branch> <decision-file>" >&2
  exit 2
fi
BRANCH="$1"
DECISION_FILE="$2"

DECISION=$(cat "$DECISION_FILE" 2> /dev/null) || DECISION=""
case "$DECISION" in
  "skip:"*)
    echo "Skipped: $DECISION"
    exit 0
    ;;
esac

export CODEMAGIC_APP_ID="${CODEMAGIC_APP_ID:-${CM_PROJECT_ID:-}}"
bash "$SCRIPT_DIR/start_ios_build_and_wait.sh" "$BRANCH"
