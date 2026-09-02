#!/bin/bash
#
# generate_diff.sh
#
# Purpose:
#   Generates a unified diff for a specific file between two git branches.
#   Shows the exact changes made to a file, with context lines for readability.
#   Used by rule application to understand what changed in each file.
#
# Input (via stdin as JSON):
#   {
#     "pr_branch": "feat/auth",                      # Required: branch with changes
#     "base_branch": "main",                         # Optional: target branch (default: "main")
#     "file": "lib/features/auth/login_screen.dart", # Required: file path to diff
#     "context_lines": 3                             # Optional: lines of context (default: 3)
#   }
#
# Output (JSON):
#   Success:
#     {
#       "file": "lib/features/auth/login_screen.dart",
#       "diff": "@@ -10,7 +10,8 @@ class LoginScreen...\n-  Text('Old'),\n+  Text('New'),\n..."
#     }
#
#   Error:
#     {
#       "error": "Human-readable message",
#       "code": "ERROR_CODE",
#       "details": {"field": "...", "branch": "...", "received": "..."}
#     }
#
# Error Codes:
#   - PARSE_ERROR: Invalid JSON input
#   - MISSING_REQUIRED_FIELD: pr_branch or file not provided
#   - INVALID_BRANCH: Branch doesn't exist in git
#   - FILE_NOT_FOUND: File doesn't exist in pr_branch
#   - GIT_ERROR: Git command execution failed
#
# Example Usage:
#   echo '{
#     "pr_branch": "feat/auth",
#     "base_branch": "main",
#     "file": "lib/features/auth/login_screen.dart",
#     "context_lines": 5
#   }' | bash skills/pr-review/scripts/generate_diff.sh
#
# Workflow Position: Step 6 (Apply Rules to Filtered Files)
#   Used by: PR Review Skill agents to see what changed in each file before applying rules

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
FILE=$(echo "$INPUT" | jq -r '.file // empty' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"
CONTEXT=$(echo "$INPUT" | jq -r '.context_lines // 3' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"

if [[ -z "$PR_BRANCH" ]]; then
  error_exit "pr_branch is required" "MISSING_REQUIRED_FIELD" "{\"field\":\"pr_branch\",\"expected\":\"string\",\"received\":\"null\"}"
fi

if [[ -z "$FILE" ]]; then
  error_exit "file is required" "MISSING_REQUIRED_FIELD" "{\"field\":\"file\",\"expected\":\"string\",\"received\":\"null\"}"
fi

# Validate branches exist
if ! git rev-parse --verify "$PR_BRANCH" >/dev/null 2>&1; then
  error_exit "Branch '$PR_BRANCH' does not exist" "INVALID_BRANCH" "{\"field\":\"pr_branch\",\"expected\":\"valid branch\",\"received\":\"$PR_BRANCH\"}"
fi

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
  error_exit "Branch '$BASE_BRANCH' does not exist" "INVALID_BRANCH" "{\"field\":\"base_branch\",\"expected\":\"valid branch\",\"received\":\"$BASE_BRANCH\"}"
fi

# Validate file exists in PR branch
if ! git show "$PR_BRANCH:$FILE" >/dev/null 2>&1; then
  error_exit "File '$FILE' not found in branch '$PR_BRANCH'" "FILE_NOT_FOUND" "{\"field\":\"file\",\"branch\":\"$PR_BRANCH\",\"received\":\"$FILE\"}"
fi

# Generate unified diff with specified context lines
DIFF=$(git diff --no-prefix -U"$CONTEXT" "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" 2>/dev/null || error_exit "Git diff failed" "GIT_ERROR")

jq -n --arg file "$FILE" --arg diff "$DIFF" '{file: $file, diff: $diff}'
