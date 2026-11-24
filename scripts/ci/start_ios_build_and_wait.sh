#!/bin/bash
set -uo pipefail

# Start the ios-debug-build workflow through the Codemagic API and wait for it to end.
# Usage: ./scripts/ci/start_ios_build_and_wait.sh <branch>
#
# Exits 0 only when the Mac build finished successfully. Every other end fails the
# calling build: a failed, canceled or timed out Mac build, an unknown status, a
# Codemagic API error (on start or while waiting), or no end after MAX_POLLS
# polls. On that last one the script also tries to cancel the Mac build.
#
# Environment:
#   CODEMAGIC_API_TOKEN, CODEMAGIC_APP_ID  required
#   CODEMAGIC_API_URL                      defaults to https://api.codemagic.io
#   POLL_INTERVAL_SECONDS                  seconds between polls, defaults to 30
#   MAX_POLLS                              polls before giving up, defaults to 90
#                                          (45 minutes at the default interval)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BRANCH="${1:-}"
if [ -z "$BRANCH" ] || [ "$#" -ne 1 ]; then
  echo "Usage: $0 <branch>" >&2
  exit 2
fi

: "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN is not set}"
: "${CODEMAGIC_APP_ID:?CODEMAGIC_APP_ID is not set}"

API_URL="${CODEMAGIC_API_URL:-https://api.codemagic.io}"
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-30}"
MAX_POLLS="${MAX_POLLS:-90}"
WORKFLOW_ID="ios-debug-build"

fail() {
  echo "❌ $1"
  exit 1
}

BODY=$(jq -nc \
  --arg appId "$CODEMAGIC_APP_ID" \
  --arg workflowId "$WORKFLOW_ID" \
  --arg branch "$BRANCH" \
  '{appId: $appId, workflowId: $workflowId, branch: $branch}')

RESPONSE=$(curl -sS --fail-with-body --max-time 30 -X POST \
  -H "Content-Type: application/json" \
  -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
  -d "$BODY" \
  "$API_URL/builds") ||
  fail "Codemagic rejected $WORKFLOW_ID on $BRANCH: $(head -c 300 <<< "$RESPONSE")"
BUILD_ID=$(jq -er '.buildId' <<< "$RESPONSE") ||
  fail "No buildId in the Codemagic response for $WORKFLOW_ID: $(head -c 300 <<< "$RESPONSE")"
case "$BUILD_ID" in
  *[!A-Za-z0-9]*) fail "The buildId Codemagic sent is not an id: $BUILD_ID" ;;
esac
echo "Started $WORKFLOW_ID on $BRANCH: build $BUILD_ID"

for ((POLL = 1; POLL <= MAX_POLLS; POLL++)); do
  RESPONSE=$(curl -sS --fail-with-body --max-time 30 \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
    "$API_URL/builds/$BUILD_ID") ||
    fail "Could not read build $BUILD_ID while waiting: $(head -c 300 <<< "$RESPONSE")"
  STATUS=$(jq -er '.build.status' <<< "$RESPONSE") ||
    fail "No build status in the Codemagic response for build $BUILD_ID: $(head -c 300 <<< "$RESPONSE")"

  case "$STATUS" in
    finished)
      echo "✅ $WORKFLOW_ID build $BUILD_ID finished"
      exit 0
      ;;
    queued | preparing | fetching | testing | building | publishing | finishing)
      echo "$WORKFLOW_ID build $BUILD_ID is $STATUS (poll $POLL of $MAX_POLLS)"
      sleep "$POLL_INTERVAL_SECONDS"
      ;;
    *)
      fail "$WORKFLOW_ID build $BUILD_ID ended with status $STATUS"
      ;;
  esac
done

bash "$SCRIPT_DIR/cancel_codemagic_builds.sh" "$BUILD_ID"
fail "$WORKFLOW_ID build $BUILD_ID did not end within $MAX_POLLS polls"
