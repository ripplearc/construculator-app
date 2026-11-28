#!/bin/bash
#
# collect_pr_text.sh
#
# Purpose:
#   Reads a pull request's title and body from GitHub so the PR Text Matches
#   Diff rule can check each claim in the PR text against the branch diff.
#
# Input (via stdin as JSON):
#   {
#     "pr_number": 670                     # Required: GitHub PR number
#   }
#
# Output (JSON):
#   Success:
#     {
#       "number": 670,
#       "title": "CA-1150: ...",
#       "body": "## Summary\n...",
#       "head": "CA-1150-feat/send-row-arrow",
#       "base": "main"
#     }
#
#   Error:
#     {
#       "error": "Human-readable message",
#       "code": "ERROR_CODE",
#       "details": {"field": "...", "expected": "...", "received": "..."}
#     }
#
# Error Codes:
#   - PARSE_ERROR: Invalid JSON input
#   - MISSING_REQUIRED_FIELD: pr_number not provided
#   - INVALID_PR_NUMBER: pr_number is not a positive integer
#   - PR_NOT_FOUND: no PR with that number in this repo
#   - AUTH_ERROR: gh is not logged in, or its token is bad
#   - GH_ERROR: any other gh failure (no network, not inside a git repo)
#   Each gh error keeps gh's own message in details.gh_error.
#
# Example Usage:
#   echo '{"pr_number": 670}' | \
#     bash .claude/skills/pr-review/scripts/collect_pr_text.sh
#
# Workflow Position: Step 1 (Collect Changed Files), only when pr_number is given
#   Used by: PR Review Skill to feed the PR Text Matches Diff rule

set -euo pipefail

# Helper function to output error as JSON
error_exit() {
  local message="$1"
  local code="$2"
  local details="${3:-}"

  local error_json="{\"error\":\"$message\",\"code\":\"$code\""
  if [[ -n "$details" ]]; then
    error_json+=",\"details\":$details"
  fi
  error_json+="}"

  echo "$error_json"
  exit 1
}

# Parse and validate input
INPUT=$(cat) || error_exit "Failed to read input" "PARSE_ERROR"

PR_NUMBER=$(echo "$INPUT" | jq -r '.pr_number // empty' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"

if [[ -z "$PR_NUMBER" ]]; then
  error_exit "pr_number is required" "MISSING_REQUIRED_FIELD" "{\"field\":\"pr_number\",\"expected\":\"positive integer\",\"received\":\"null\"}"
fi

if ! [[ "$PR_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  error_exit "pr_number must be a positive integer" "INVALID_PR_NUMBER" "$(jq -nc --arg received "$PR_NUMBER" '{field: "pr_number", expected: "positive integer", received: $received}')"
fi

GH_STDERR_FILE=$(mktemp)
trap 'rm -f "$GH_STDERR_FILE"' EXIT
if ! PR_JSON=$(gh pr view "$PR_NUMBER" --json number,title,body,headRefName,baseRefName 2>"$GH_STDERR_FILE"); then
  GH_STDERR=$(cat "$GH_STDERR_FILE")
  case "$GH_STDERR" in
    *"Could not resolve to a PullRequest"*) GH_CODE="PR_NOT_FOUND" ;;
    *"HTTP 401"*|*"gh auth login"*) GH_CODE="AUTH_ERROR" ;;
    *) GH_CODE="GH_ERROR" ;;
  esac
  error_exit "Could not read PR #$PR_NUMBER with gh" "$GH_CODE" "$(jq -nc --arg received "$PR_NUMBER" --arg gh_error "$GH_STDERR" '{field: "pr_number", received: $received, gh_error: $gh_error}')"
fi

echo "$PR_JSON" | jq '{number, title, body, head: .headRefName, base: .baseRefName}'
