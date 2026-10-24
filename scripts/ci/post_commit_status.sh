#!/bin/bash
set -euo pipefail

# Post a GitHub commit status.
# Usage: ./scripts/ci/post_commit_status.sh <sha> <context> <state> <description> [target-url]
#
# state is one of: error, failure, pending, success.
#
# Environment:
#   GH_REPO, GITHUB_TOKEN   required
#   GITHUB_API_URL          defaults to https://api.github.com
#   DRY_RUN=true            print the status and send nothing

SHA="${1:-}"
CONTEXT="${2:-}"
STATE="${3:-}"
DESCRIPTION="${4:-}"
TARGET_URL="${5:-}"

if [ -z "$SHA" ] || [ -z "$CONTEXT" ] || [ -z "$STATE" ] || [ -z "$DESCRIPTION" ]; then
  echo "Usage: $0 <sha> <context> <state> <description> [target-url]" >&2
  exit 2
fi

case "$STATE" in
  error | failure | pending | success) ;;
  *)
    echo "❌ Unknown state: $STATE" >&2
    exit 2
    ;;
esac

BODY=$(jq -nc \
  --arg state "$STATE" \
  --arg context "$CONTEXT" \
  --arg description "$DESCRIPTION" \
  --arg target_url "$TARGET_URL" \
  '{state: $state, context: $context, description: $description}
   + (if $target_url == "" then {} else {target_url: $target_url} end)')

if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "DRY RUN: would post to $SHA: $BODY"
  exit 0
fi

: "${GH_REPO:?GH_REPO is not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"

API_URL="${GITHUB_API_URL:-https://api.github.com}"
if ! RESPONSE=$(curl -sS --fail-with-body -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$BODY" \
  "$API_URL/repos/$GH_REPO/statuses/$SHA"); then
  echo "❌ GitHub rejected the status for $SHA: $RESPONSE"
  exit 1
fi
echo "✅ Posted $CONTEXT=$STATE on $SHA"
