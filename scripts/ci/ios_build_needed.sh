#!/bin/bash
set -euo pipefail

# Decide whether #RunCheck must run the iOS debug build for a pull request.
# Usage: ./scripts/ci/ios_build_needed.sh
#        ./scripts/ci/ios_build_needed.sh --classify <path>
#
# Prints one line on stdout: "run: <reason>" or "skip: <reason>".
# "skip" is printed only when every changed file is listed as not iOS-related in
# ios_build_paths.conf, the comment does not ask for iOS, and Codemagic has not
# already reported an iOS result on the head commit. A file the list does not
# mention, and anything else the script cannot establish, answers "run".
#
# --classify prints "ios", "other" or "unknown" for one path.
#
# Environment:
#   GH_REPO, GITHUB_TOKEN, PR_NUMBER, HEAD_SHA   required
#   COMMENT_BODY                                 text of the #RunCheck comment
#   GITHUB_API_URL                               defaults to https://api.github.com

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATHS_FILE="${IOS_BUILD_PATHS_FILE:-$SCRIPT_DIR/ios_build_paths.conf}"

# Prints "ios", "other" or "unknown", then the matching pattern.
classify() {
  local path="$1" kind pattern
  while read -r kind pattern; do
    case "$kind" in
      ios | other) ;;
      *) continue ;;
    esac
    case "$pattern" in
      */)
        case "$path" in "$pattern"*) echo "$kind $pattern"; return 0 ;; esac
        ;;
      *)
        # shellcheck disable=SC2254 # the pattern is a glob on purpose
        case "$path" in $pattern) echo "$kind $pattern"; return 0 ;; esac
        ;;
    esac
  done < <(grep -E '^(ios|other)[[:space:]]' "$PATHS_FILE")
  echo "unknown"
}

if [ "${1:-}" = "--classify" ]; then
  classify "${2:?--classify needs a path}"
  exit 0
fi

: "${GH_REPO:?GH_REPO is not set}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"
: "${PR_NUMBER:?PR_NUMBER is not set}"
: "${HEAD_SHA:?HEAD_SHA is not set}"

API_URL="${GITHUB_API_URL:-https://api.github.com}"
FILES_PER_PAGE=100
GITHUB_FILE_LIST_LIMIT=3000

api_get() {
  curl -sS --fail-with-body \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "$API_URL/repos/$GH_REPO/$1"
}

run_because() {
  echo "run: $1"
  exit 0
}

if echo "${COMMENT_BODY:-}" | grep -Eiq '(^|[[:space:]])#runcheck[[:space:]]+ios([[:space:]]|$)'; then
  run_because "the comment asks for it with #RunCheck ios"
fi

CHECK_RUNS=$(api_get "commits/$HEAD_SHA/check-runs?per_page=100&check_name=Ios%20Debug%20Build") ||
  run_because "could not read the check runs on $HEAD_SHA"
EXISTING=$(jq -er '[.check_runs[]
    | select(.name == "Ios Debug Build" and .app.slug == "codemagic-ci-cd")
    | select(.conclusion != "cancelled" and .conclusion != "timed_out")] | length' <<< "$CHECK_RUNS") ||
  run_because "the check runs on $HEAD_SHA could not be read"
if [ "$EXISTING" -gt 0 ]; then
  run_because "Codemagic already reported an iOS result on this commit"
fi

PAGE=1
TOTAL=0
while :; do
  FILES_JSON=$(api_get "pulls/$PR_NUMBER/files?per_page=$FILES_PER_PAGE&page=$PAGE") ||
    run_because "could not list the files of pull request $PR_NUMBER"
  COUNT=$(jq -er 'length' <<< "$FILES_JSON") ||
    run_because "the file list of pull request $PR_NUMBER could not be read"
  TOTAL=$((TOTAL + COUNT))

  while IFS= read -r file; do
    [ -z "$file" ] && continue
    MATCH=$(classify "$file")
    case "$MATCH" in
      "ios "*) run_because "$file matches ${MATCH#ios }" ;;
      unknown) run_because "$file is not listed in ios_build_paths.conf" ;;
    esac
  done < <(jq -r '.[] | .filename, (.previous_filename // empty)' <<< "$FILES_JSON")

  [ "$COUNT" -lt "$FILES_PER_PAGE" ] && break
  PAGE=$((PAGE + 1))
done

if [ "$TOTAL" -ge "$GITHUB_FILE_LIST_LIMIT" ]; then
  run_because "GitHub lists at most $GITHUB_FILE_LIST_LIMIT files, so the full list cannot be checked"
fi

echo "skip: no iOS-related files changed ($TOTAL files checked)"
