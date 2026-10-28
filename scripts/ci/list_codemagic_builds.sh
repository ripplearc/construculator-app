#!/bin/bash
set -euo pipefail

# List the Codemagic builds of one branch.
# Usage: ./scripts/ci/list_codemagic_builds.sh <branch>
#
# Prints a JSON array on stdout, one object per build on the first page Codemagic
# returns (further pages are not read):
#   {"id": "...", "workflow": "...", "status": "...", "commit": "...", "createdAt": "..."}
# "workflow" is the id of the workflow in codemagic.yaml (fileWorkflowId; the
# workflowId field is null for those). A field Codemagic does not send is null.
# The notes on stderr name the fields Codemagic sent and the statuses it reported.
# The notes on stderr also give the number of builds read, so a cut-off list shows.
#
# Environment:
#   CODEMAGIC_API_TOKEN, CODEMAGIC_APP_ID   required
#   CODEMAGIC_API_URL                       defaults to https://api.codemagic.io

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <branch>" >&2
  exit 2
fi
BRANCH="$1"

: "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN is not set}"
: "${CODEMAGIC_APP_ID:?CODEMAGIC_APP_ID is not set}"

API_URL="${CODEMAGIC_API_URL:-https://api.codemagic.io}"
ENCODED_BRANCH=$(jq -rn --arg branch "$BRANCH" '$branch | @uri')

if ! RESPONSE=$(curl -sS --fail-with-body --max-time 15 \
  -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
  "$API_URL/builds?appId=$CODEMAGIC_APP_ID&branch=$ENCODED_BRANCH"); then
  echo "❌ Could not list the Codemagic builds of $BRANCH: $(head -c 300 <<< "$RESPONSE")" >&2
  exit 1
fi

if ! BUILDS=$(jq -ce 'if type == "array" then . else .builds end | select(type == "array" and all(type == "object"))' <<< "$RESPONSE"); then
  echo "❌ The Codemagic answer for $BRANCH has no list of builds: $(head -c 300 <<< "$RESPONSE")" >&2
  exit 1
fi

echo "Builds read: $(jq 'length' <<< "$BUILDS")" >&2
echo "Fields on a build: $(jq -r '[.[0] // {} | keys[]] | join(", ")' <<< "$BUILDS")" >&2
echo "Statuses seen: $(jq -r '[.[].status] | unique | join(", ")' <<< "$BUILDS")" >&2

jq -c '[.[] | {
  id: ._id,
  workflow: .fileWorkflowId,
  status: .status,
  commit: .commit.hash?,
  createdAt: .createdAt
}]' <<< "$BUILDS"
