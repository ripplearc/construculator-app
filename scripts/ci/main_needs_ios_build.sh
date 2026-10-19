#!/bin/bash
set -euo pipefail

# Decide whether the nightly iOS debug build should run on main.
# Usage: ./scripts/ci/main_needs_ios_build.sh
#
# Prints exactly one word on stdout: "build" or "skip". Everything else goes to
# stderr. The answer is "skip" only when the tip of main already has an
# "Ios Debug Build" check run from the Codemagic app that is queued, running,
# successful or failed. A canceled or timed-out run does not count as a result.
# If anything about the lookup fails, the answer is "build", so an API problem
# can cost one build but never hides a broken main.
#
# Environment:
#   GH_REPO            owner/name of the repository (required)
#   GITHUB_TOKEN       token that can read check runs (required)
#   GITHUB_API_URL     defaults to https://api.github.com
#   MAIN_SHA           use this commit instead of looking up the tip of main

: "${GH_REPO:?GH_REPO is not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"

API_URL="${GITHUB_API_URL:-https://api.github.com}"
CHECK_NAME="Ios Debug Build"
CODEMAGIC_APP_SLUG="codemagic-ci-cd"

api_get() {
  curl -sS --fail-with-body \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$API_URL/repos/$GH_REPO/$1"
}

build_because() {
  echo "$1" >&2
  echo "build"
  exit 0
}

SHA="${MAIN_SHA:-}"
if [ -z "$SHA" ]; then
  RESPONSE=$(api_get "commits/main") ||
    build_because "Could not read the tip of main ($RESPONSE). Building to be safe."
  SHA=$(jq -er '.sha' <<< "$RESPONSE") ||
    build_because "No commit sha in the answer for main. Building to be safe."
fi

RESPONSE=$(api_get "commits/$SHA/check-runs?per_page=100&check_name=Ios%20Debug%20Build") ||
  build_because "Could not read check runs for $SHA ($RESPONSE). Building to be safe."

HAS_RESULT=$(jq -r --arg app "$CODEMAGIC_APP_SLUG" --arg name "$CHECK_NAME" '
  [.check_runs[]
   | select(.name == $name and .app.slug == $app)
   | select(.status == "queued" or .status == "in_progress"
            or .conclusion == "success" or .conclusion == "failure")
  ] | length > 0' <<< "$RESPONSE") ||
  build_because "Check runs for $SHA could not be read. Building to be safe."

if [ "$HAS_RESULT" = "true" ]; then
  echo "main at $SHA already has an $CHECK_NAME result from Codemagic." >&2
  echo "skip"
else
  echo "main at $SHA has no $CHECK_NAME result from Codemagic yet." >&2
  echo "build"
fi
