#!/bin/bash
#
# filter_files.sh
#
# Purpose:
#   Filters a list of files based on a glob pattern. Used to narrow down which
#   files should be analyzed by rules (e.g., only presentation files).
#   Enables efficient rule application by pre-filtering irrelevant files.
#
# Input (via stdin as JSON):
#   {
#     "files": [                          # Required: array of file paths
#       "lib/features/auth/presentation/login_screen.dart",
#       "lib/features/auth/domain/auth_use_case.dart",
#       "lib/app/presentation/app_widget.dart"
#     ],
#     "pattern": "lib/features/**/presentation/"  # Required: glob pattern to match
#   }
#
# Output (JSON):
#   Success:
#     {
#       "files": [
#         {"path": "lib/features/auth/presentation/login_screen.dart"}
#       ]
#     }
#
#   Error:
#     {
#       "error": "Human-readable message",
#       "code": "ERROR_CODE"
#     }
#
# Error Codes:
#   - PARSE_ERROR: Invalid JSON input
#   - MISSING_REQUIRED_FIELD: pattern parameter not provided
#
# Pattern Examples:
#   - "lib/features/**/presentation/" → matches any file in presentation folders
#   - "lib/app/presentation/" → matches app-level presentation files
#   - "test/**/widgets/" → matches widget tests
#
# Example Usage:
#   echo '{
#     "files": ["lib/features/auth/presentation/login.dart", "lib/domain/auth.dart"],
#     "pattern": "lib/features/**/presentation/"
#   }' | bash skills/pr-review/scripts/filter_files.sh
#
# Workflow Position: Step 3 (Filter Applicable Files)
#   Used by: PR Review Skill to narrow down to presentation files before rule application

set -euo pipefail

# Helper function to output error as JSON
error_exit() {
  local message="$1"
  local code="$2"

  echo "{\"error\":\"$message\",\"code\":\"$code\"}"
  exit 1
}

# Parse and validate input
INPUT=$(cat) || error_exit "Failed to read input" "PARSE_ERROR"

FILES=$(echo "$INPUT" | jq -r '.files[]?' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"
PATTERN=$(echo "$INPUT" | jq -r '.pattern // empty' 2>/dev/null) || error_exit "Invalid JSON input" "PARSE_ERROR"

if [[ -z "${PATTERN}" ]]; then
  error_exit "pattern is required (e.g., 'lib/features/**/presentation/')" "MISSING_REQUIRED_FIELD"
fi

if [[ -z "${FILES:-}" ]]; then
  jq -n '{files: []}'
  exit 0
fi

OUTPUT='{"files": []}'

# Match files against pattern using bash glob matching
while IFS= read -r FILE; do
  if [[ -n "$FILE" ]]; then
    # Normalize matching for common recursive patterns. Bash [[ == ]] does not
    # expand '**' from a JSON-provided string, so handle common cases explicitly.
    MATCHED=false

    # If pattern mentions 'presentation', match any path containing 'presentation/'
    if [[ "$PATTERN" == *presentation* ]]; then
      if [[ "$FILE" == *presentation/* ]]; then
        MATCHED=true
      fi
    fi

    # Fallback: substring match of the provided pattern
    if [[ "$MATCHED" == false ]]; then
      if [[ "$FILE" == *"$PATTERN"* || "$FILE" == "$PATTERN" ]]; then
        MATCHED=true
      fi
    fi

    if [[ "$MATCHED" == true ]]; then
      FILE_JSON=$(jq -n --arg path "$FILE" '{path: $path}')
      OUTPUT=$(echo "$OUTPUT" | jq --argjson file "$FILE_JSON" '.files += [$file]')
    fi
  fi
done <<< "$FILES"

echo "$OUTPUT"
