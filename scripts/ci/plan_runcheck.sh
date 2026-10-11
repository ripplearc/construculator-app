#!/bin/bash
set -euo pipefail

# Plan a #RunCheck: which Codemagic workflows already have a result on the pull
# request head commit, and which builds on older commits of the pull request are
# still queued or running.
# Usage: ./scripts/ci/plan_runcheck.sh [workflow-id...]
#        (default: pre-check comprehensive-check ios-debug-build)
#
# Prints one JSON object on stdout: {"skip": [...], "cancel": [...], "comment": "..."}
#   skip     workflow ids that must not be started again
#   cancel   Codemagic build ids to cancel
#   comment  Markdown for the pull request, empty when nothing is skipped
# Everything else goes to stderr. A GitHub error never adds a skip or a cancel,
# so a lookup problem can only cost an extra build.
#
# A workflow is skipped when Codemagic has, on the head commit, a check run with
# its name that is queued, running, successful or failed. A canceled or timed-out
# run is not a result. `#RunCheck force` in the comment starts a workflow again
# after a finished run, but never while one is still running.
#
# Environment:
#   GH_REPO, GITHUB_TOKEN, PR_NUMBER, HEAD_SHA   required
#   COMMENT_BODY                                 text of the #RunCheck comment
#   GITHUB_API_URL                               defaults to https://api.github.com

: "${GH_REPO:?GH_REPO is not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"
: "${PR_NUMBER:?PR_NUMBER is not set}"
: "${HEAD_SHA:?HEAD_SHA is not set}"

API_URL="${GITHUB_API_URL:-https://api.github.com}"
CODEMAGIC_APP_SLUG="codemagic-ci-cd"
OLDER_COMMITS_TO_CHECK=10

if [ "$#" -eq 0 ]; then
  set -- pre-check comprehensive-check ios-debug-build
fi

api_get() {
  curl -sS --fail-with-body \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$API_URL/repos/$GH_REPO/$1"
}

check_name_of() {
  case "$1" in
    pre-check) echo "Pre-check" ;;
    comprehensive-check) echo "Comprehensive Check" ;;
    ios-debug-build) echo "Ios Debug Build" ;;
    *) return 1 ;;
  esac
}

FORCE=false
if echo "${COMMENT_BODY:-}" | grep -Eiq '(^|[[:space:]])#runcheck[[:space:]]+force([[:space:]]|$)'; then
  FORCE=true
fi

SKIP=""
COMMENT_LINES=""

if HEAD_RUNS=$(api_get "commits/$HEAD_SHA/check-runs?per_page=100") &&
  jq -e '.check_runs | type == "array"' <<< "$HEAD_RUNS" > /dev/null 2>&1; then
  for WORKFLOW_ID in "$@"; do
    CHECK_NAME=$(check_name_of "$WORKFLOW_ID") || continue
    VERDICT=$(jq -r --arg app "$CODEMAGIC_APP_SLUG" --arg name "$CHECK_NAME" --arg force "$FORCE" '
      [.check_runs[] | select(.app.slug == $app and .name == $name)] as $runs
      | ($runs | map(select(.status == "queued" or .status == "in_progress")) | first) as $running
      | ($runs | map(select(.status == "completed"
                            and (.conclusion == "success" or .conclusion == "failure"))) | first) as $done
      | if $running != null then "still running\t" + ($running.details_url // "")
        elif $done != null and $force != "true" then $done.conclusion + "\t" + ($done.details_url // "")
        else "" end' <<< "$HEAD_RUNS")
    [ -z "$VERDICT" ] && continue
    SKIP="$SKIP $WORKFLOW_ID"
    STATE="${VERDICT%%$'\t'*}"
    LINK="${VERDICT#*$'\t'}"
    COMMENT_LINES="${COMMENT_LINES}- ${CHECK_NAME}: ${STATE} ([build](${LINK}))"$'\n'
    echo "Skipping $WORKFLOW_ID: $STATE on $HEAD_SHA" >&2
  done
else
  echo "Could not read the check runs on $HEAD_SHA. Nothing is skipped." >&2
fi

CANCEL=""
if COMMITS=$(api_get "pulls/$PR_NUMBER/commits?per_page=100") &&
  OLDER=$(jq -er --arg head "$HEAD_SHA" --argjson n "$OLDER_COMMITS_TO_CHECK" \
    '[.[].sha | select(. != $head)] | .[-$n:] | .[]' <<< "$COMMITS"); then
  for SHA in $OLDER; do
    if ! RUNS=$(api_get "commits/$SHA/check-runs?per_page=100"); then
      echo "Could not read the check runs on $SHA. Not cancelling its builds." >&2
      continue
    fi
    IDS=$(jq -r --arg app "$CODEMAGIC_APP_SLUG" '
      .check_runs[]
      | select(.app.slug == $app and (.status == "queued" or .status == "in_progress"))
      | .external_id // empty' <<< "$RUNS" 2> /dev/null) || IDS=""
    CANCEL="$CANCEL $IDS"
  done
else
  echo "No older commits to check for running builds." >&2
fi

COMMENT=""
if [ -n "$COMMENT_LINES" ]; then
  COMMENT="This commit (\`${HEAD_SHA:0:7}\`) already has Codemagic results, so \`#RunCheck\` did not start these again:"$'\n\n'
  COMMENT="${COMMENT}${COMMENT_LINES}"$'\n'
  COMMENT="${COMMENT}Push a new commit, or write \`#RunCheck force\` to run again (for example after a flaky failure)."
fi

jq -n --arg skip "$SKIP" --arg cancel "$CANCEL" --arg comment "$COMMENT" '
  {skip: ($skip | split(" ") | map(select(. != ""))),
   cancel: ($cancel | split(" ") | map(select(. != ""))),
   comment: $comment}'
