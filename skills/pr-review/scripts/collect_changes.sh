#!/bin/bash
#
# collect_changes.sh
#
# Purpose:
#   Identifies all changed files between two git branches and returns them as JSON.
#   Automatically excludes generated code (.g.dart, .freezed.dart, etc.) and binary
#   files (images, videos, archives, etc.) to focus on files worth reviewing.
#
# Input (via stdin as JSON):
#   {
#     "pr_branch": "feat/login",           # Required: branch with changes
#     "base_branch": "main"                # Optional: target branch (default: "main")
#   }
#
# Output (JSON):
#   Success:
#     {
#       "files": [
#         {"path": "lib/features/auth/login.dart", "status": "M"},
#         {"path": "lib/features/auth/login_screen.dart", "status": "A"}
#       ]
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
#   - MISSING_REQUIRED_FIELD: pr_branch not provided
#   - INVALID_BRANCH: Branch doesn't exist in git
#   - GIT_ERROR: Git command execution failed
#
# Example Usage:
#   echo '{"pr_branch": "feat/auth", "base_branch": "main"}' | \
#     bash skills/pr-review/scripts/collect_changes.sh
#
# Workflow Position: Step 2 (Collect Changed Files)
#   Used by: PR Review Skill to gather list of files that changed in the PR

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

PR_BRANCH=$(echo "$INPUT" | jq -r '.pr_branch // empty' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"
BASE_BRANCH=$(echo "$INPUT" | jq -r '.base_branch // "main"' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"

if [[ -z "$PR_BRANCH" ]]; then
  error_exit "pr_branch is required" "MISSING_REQUIRED_FIELD" "{\"field\":\"pr_branch\",\"expected\":\"string\",\"received\":\"null\"}"
fi

# Validate branches exist
if ! git rev-parse --verify "$PR_BRANCH" >/dev/null 2>&1; then
  error_exit "Branch '$PR_BRANCH' does not exist" "INVALID_BRANCH" "{\"field\":\"pr_branch\",\"expected\":\"valid branch\",\"received\":\"$PR_BRANCH\"}"
fi

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
  error_exit "Branch '$BASE_BRANCH' does not exist" "INVALID_BRANCH" "{\"field\":\"base_branch\",\"expected\":\"valid branch\",\"received\":\"$BASE_BRANCH\"}"
fi

DIFF_OUTPUT=$(git diff --name-status "$BASE_BRANCH".."$PR_BRANCH" 2>/dev/null || true)

FILES_JSON='[]'

# Process single diff output (status and path per line) and filter generated/binary files
while IFS=$'\t' read -r STATUS FILE; do
  if [[ -z "$FILE" ]]; then
    # Skip empty lines
    continue
  fi

  # Skip generated and binary files
  if echo "$FILE" | grep -Eq '\.(g\.dart|freezed\.dart|gr\.dart|config\.dart|chopper\.dart|mocks\.dart)$'; then
    continue
  fi
  if echo "$FILE" | grep -Eq '\.(png|jpg|jpeg|gif|svg|ico|webp|ttf|otf|woff|woff2|pdf|zip|tar|gz|rar|7z|exe|dll|so|dylib)$'; then
    continue
  fi

  FILE_JSON=$(jq -n --arg path "$FILE" --arg status "${STATUS:-M}" '{path: $path, status: $status}')
  FILES_JSON=$(jq --argjson file "$FILE_JSON" '. + [$file]' <<< "$FILES_JSON") || error_exit "Failed to build JSON" "PARSE_ERROR"
done <<< "$DIFF_OUTPUT"

jq -n --argjson files "$FILES_JSON" '{files: $files}'
