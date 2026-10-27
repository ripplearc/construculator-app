#!/bin/bash
set -euo pipefail

# Start Codemagic builds on one branch through the Codemagic API.
# Usage: ./scripts/ci/trigger_codemagic_builds.sh <branch> <workflow-id>...
#
# Environment:
#   CODEMAGIC_API_TOKEN, CODEMAGIC_APP_ID  required unless DRY_RUN=true
#   CODEMAGIC_API_URL                      defaults to https://api.codemagic.io
#   DRY_RUN=true                           print each request body and send nothing
#   SKIP_WORKFLOWS                         space-separated workflow ids to leave out
#   COMMENT_BODY                           text of the #RunCheck comment; "#RunCheck ios"
#                                          sends FORCE_IOS_BUILD=true so the iOS build
#                                          cannot skip itself
#
# Every workflow is attempted even if an earlier one fails. The script exits
# non-zero if any request fails or the response has no buildId.

BRANCH="${1:-}"
if [ -z "$BRANCH" ] || [ "$#" -lt 2 ]; then
  echo "Usage: $0 <branch> <workflow-id>..." >&2
  exit 2
fi
shift

API_URL="${CODEMAGIC_API_URL:-https://api.codemagic.io}"
DRY_RUN="${DRY_RUN:-false}"

if [ "$DRY_RUN" != "true" ]; then
  : "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN is not set}"
  : "${CODEMAGIC_APP_ID:?CODEMAGIC_APP_ID is not set}"
fi

write_summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    echo "$1" >> "$GITHUB_STEP_SUMMARY"
  fi
}

FORCE_IOS_BUILD=false
if echo "${COMMENT_BODY:-}" | grep -Eiq '(^|[[:space:]])#runcheck[[:space:]]+ios([[:space:]]|$)'; then
  FORCE_IOS_BUILD=true
fi

FAILURES=0

is_skipped() {
  local skipped
  for skipped in ${SKIP_WORKFLOWS:-}; do
    [ "$skipped" = "$1" ] && return 0
  done
  return 1
}

for WORKFLOW_ID in "$@"; do
  if is_skipped "$WORKFLOW_ID"; then
    echo "Skipping $WORKFLOW_ID: listed in SKIP_WORKFLOWS"
    write_summary "- Skipped \`$WORKFLOW_ID\`: listed in SKIP_WORKFLOWS"
    continue
  fi

  BODY=$(jq -nc \
    --arg appId "${CODEMAGIC_APP_ID:-}" \
    --arg workflowId "$WORKFLOW_ID" \
    --arg branch "$BRANCH" \
    --arg forceIos "$FORCE_IOS_BUILD" \
    '{appId: $appId, workflowId: $workflowId, branch: $branch,
      environment: {variables: {FORCE_FAIL: "false", FORCE_IOS_BUILD: $forceIos}}}')

  if [ "$DRY_RUN" = "true" ]; then
    echo "DRY RUN: would start $WORKFLOW_ID on $BRANCH: $BODY"
    write_summary "- DRY RUN: would start \`$WORKFLOW_ID\` on \`$BRANCH\`"
    continue
  fi

  if ! RESPONSE=$(curl -sS --fail-with-body -X POST \
    -H "Content-Type: application/json" \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
    -d "$BODY" \
    "$API_URL/builds"); then
    echo "❌ Codemagic rejected $WORKFLOW_ID on $BRANCH: $RESPONSE"
    write_summary "- ❌ \`$WORKFLOW_ID\` was not started: $RESPONSE"
    FAILURES=$((FAILURES + 1))
    continue
  fi

  if ! BUILD_ID=$(echo "$RESPONSE" | jq -er '.buildId'); then
    echo "❌ No buildId in the Codemagic response for $WORKFLOW_ID: $RESPONSE"
    write_summary "- ❌ \`$WORKFLOW_ID\` returned no buildId: $RESPONSE"
    FAILURES=$((FAILURES + 1))
    continue
  fi

  echo "✅ Started $WORKFLOW_ID on $BRANCH: build $BUILD_ID"
  write_summary "- ✅ Started \`$WORKFLOW_ID\` on \`$BRANCH\`: build \`$BUILD_ID\`"
done

if [ "$FAILURES" -gt 0 ]; then
  echo "❌ $FAILURES Codemagic build(s) did not start."
  exit 1
fi
