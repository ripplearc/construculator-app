#!/bin/bash
set -euo pipefail

# Cancel Codemagic builds by id.
# Usage: ./scripts/ci/cancel_codemagic_builds.sh [build-id...]
#
# Cancelling is best effort. Every id is tried, and the script exits 1 if any
# request failed. Codemagic answers 208 for a build that has already finished,
# which counts as success. With no ids it does nothing.
#
# Environment:
#   CODEMAGIC_API_TOKEN   required unless DRY_RUN=true
#   CODEMAGIC_API_URL     defaults to https://api.codemagic.io
#   DRY_RUN=true          print the builds and cancel nothing

if [ "$#" -eq 0 ]; then
  echo "No older builds to cancel."
  exit 0
fi

API_URL="${CODEMAGIC_API_URL:-https://api.codemagic.io}"
FAILURES=0

for BUILD_ID in "$@"; do
  case "$BUILD_ID" in
    *[!A-Za-z0-9]*)
      echo "❌ Not a build id: $BUILD_ID"
      FAILURES=$((FAILURES + 1))
      continue
      ;;
  esac

  if [ "${DRY_RUN:-false}" = "true" ]; then
    echo "DRY RUN: would cancel build $BUILD_ID"
    continue
  fi

  : "${CODEMAGIC_API_TOKEN:?CODEMAGIC_API_TOKEN is not set}"
  if RESPONSE=$(curl -sS --fail-with-body -X POST \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
    "$API_URL/builds/$BUILD_ID/cancel"); then
    echo "✅ Cancelled build $BUILD_ID"
  else
    echo "❌ Could not cancel build $BUILD_ID: $RESPONSE"
    FAILURES=$((FAILURES + 1))
  fi
done

if [ "$FAILURES" -gt 0 ]; then
  exit 1
fi
