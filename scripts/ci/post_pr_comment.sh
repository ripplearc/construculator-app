#!/bin/bash
set -euo pipefail

# Comment on a pull request.
# Usage: ./scripts/ci/post_pr_comment.sh <pr-number> <body-file>
#
# Posts nothing when the file is empty. Use the workflow's GITHUB_TOKEN, because
# a comment made with it does not start another workflow run.
#
# Environment:
#   GH_REPO, GITHUB_TOKEN   required unless DRY_RUN=true
#   GITHUB_API_URL          defaults to https://api.github.com
#   DRY_RUN=true            print the comment and send nothing

PR_NUMBER="${1:-}"
BODY_FILE="${2:-}"
if [ -z "$PR_NUMBER" ] || [ -z "$BODY_FILE" ]; then
  echo "Usage: $0 <pr-number> <body-file>" >&2
  exit 2
fi

if [ ! -s "$BODY_FILE" ]; then
  echo "Nothing to say. No comment posted."
  exit 0
fi

if [ "${DRY_RUN:-false}" = "true" ]; then
  echo "DRY RUN: would comment on #$PR_NUMBER:"
  cat "$BODY_FILE"
  exit 0
fi

: "${GH_REPO:?GH_REPO is not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"

API_URL="${GITHUB_API_URL:-https://api.github.com}"
BODY=$(jq -n --rawfile body "$BODY_FILE" '{body: $body}')
if ! RESPONSE=$(curl -sS --fail-with-body -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d "$BODY" \
  "$API_URL/repos/$GH_REPO/issues/$PR_NUMBER/comments"); then
  echo "❌ GitHub rejected the comment on #$PR_NUMBER: $RESPONSE"
  exit 1
fi
echo "✅ Commented on #$PR_NUMBER"
