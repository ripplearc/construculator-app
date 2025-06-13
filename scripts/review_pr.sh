#!/bin/bash

# PR Review File Generator for AI Code Review
# Usage examples:
# ./create_pr_review.sh feature-branch main
# ./create_pr_review.sh bugfix/login-fix develop login_fix_review.txt
# ./create_pr_review.sh release/v2.0 master release_v2_review.txt
# ./create_pr_review.sh origin/feature-x upstream/main fork_review.txt

# Check if enough parameters are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 pr_branch base_branch [output_file]"
    echo "Example: $0 feature-branch main pr_review.txt"
    exit 1
fi

# Set variables from parameters
PR_BRANCH="$1"      # Branch with your changes
BASE_BRANCH="$2"    # Branch you want to merge into (target)
OUTPUT_FILE="${3:-pr_review_for_claude.txt}"  # Default filename if not provided

# Verify branches exist
if ! git rev-parse --verify "$PR_BRANCH" >/dev/null 2>&1; then
    echo "Error: PR branch '$PR_BRANCH' does not exist"
    exit 1
fi

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo "Error: Base branch '$BASE_BRANCH' does not exist"
    exit 1
fi

# Create header
echo "# PR Review Request: $PR_BRANCH → $BASE_BRANCH" > "$OUTPUT_FILE"
echo "PR Branch: $PR_BRANCH (with changes)" >> "$OUTPUT_FILE"
echo "Base Branch: $BASE_BRANCH (target)" >> "$OUTPUT_FILE"
echo "Date: $(date)" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# Get list of changed files - show what's in PR_BRANCH that's not in BASE_BRANCH
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH".."$PR_BRANCH")

# Check if there are any changes
if [ -z "$CHANGED_FILES" ]; then
    echo "No changes found between PR branch $PR_BRANCH and base branch $BASE_BRANCH"
    exit 0
fi

# Generate overview table
echo "## CHANGES OVERVIEW" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| File | Changes | Type |" >> "$OUTPUT_FILE"
echo "|------|---------|------|" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Get file status (modified, added, deleted)
    STATUS=$(git diff --name-status "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | cut -f1)
    
    case $STATUS in
        M) STATUS_DESC="Modified" ;;
        A) STATUS_DESC="Added" ;;
        D) STATUS_DESC="Deleted" ;;
        R*) STATUS_DESC="Renamed" ;;
        C*) STATUS_DESC="Copied" ;;
        *) STATUS_DESC="Changed" ;;
    esac
    
    # Get file type
    if git show "$PR_BRANCH":"$FILE" &>/dev/null 2>&1; then
        if file --mime-type "$FILE" 2>/dev/null | grep -q "text/"; then
            FILE_TYPE="Text"
            # Count lines changed
            STATS=$(git diff --stat "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | tail -n1)
            echo "| $FILE | $STATUS_DESC: $STATS | $FILE_TYPE |" >> "$OUTPUT_FILE"
        else
            FILE_TYPE="Binary"
            echo "| $FILE | $STATUS_DESC | $FILE_TYPE |" >> "$OUTPUT_FILE"
        fi
    else
        FILE_TYPE="Unknown"
        echo "| $FILE | $STATUS_DESC | $FILE_TYPE |" >> "$OUTPUT_FILE"
    fi
done

echo "" >> "$OUTPUT_FILE"

# Create GitHub-style diff with context
echo "## GITHUB-STYLE DIFF WITH CONTEXT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Skip binary files
    if git show "$PR_BRANCH":"$FILE" &>/dev/null 2>&1 && ! file --mime-type "$FILE" 2>/dev/null | grep -q "binary"; then
        # Get the file extension for syntax highlighting
        FILE_EXT="${FILE##*.}"
        
        # Determine if file is added, modified, or deleted
        STATUS=$(git diff --name-status "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" | cut -f1)
        
        case $STATUS in
            A) CHANGE_TYPE="Added" ;;
            M) CHANGE_TYPE="Modified" ;;
            D) CHANGE_TYPE="Deleted" ;;
            R*) CHANGE_TYPE="Renamed" ;;
            C*) CHANGE_TYPE="Copied" ;;
            *) CHANGE_TYPE="Changed" ;;
        esac
        
        echo "### $FILE ($CHANGE_TYPE)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Generate GitHub-style diff with context
        # Using -U3 to show 3 lines of context before and after changes
        echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
        
        # Use git diff directly with line numbers (simplified approach)
        git diff --no-prefix -U3 "$BASE_BRANCH".."$PR_BRANCH" -- "$FILE" >> "$OUTPUT_FILE"
        
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Add placeholder for code review comments
        echo "#### Suggestions for $FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "<!-- Example suggestion format below -->" >> "$OUTPUT_FILE"
        echo "<!--" >> "$OUTPUT_FILE"
        echo "**Line XX:** ✅/❌ Comment about the code" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "**Suggested Change:**" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
        echo "// Suggested implementation" >> "$OUTPUT_FILE"
        echo "\`\`\`" >> "$OUTPUT_FILE"
        echo "-->" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        echo "### $FILE (Binary or Deleted - diff not shown)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add full file contents for context
echo "## COMPLETE FILE CONTENTS FOR CONTEXT" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

for FILE in $CHANGED_FILES; do
    # Check if file exists in PR branch
    if git show "$PR_BRANCH":"$FILE" &>/dev/null; then
        # Skip binary files
        if ! git cat-file -t "$PR_BRANCH":"$FILE" | grep -q "blob" || ! file --mime-type "$FILE" 2>/dev/null | grep -qv "binary"; then
            # Get the file extension for syntax highlighting
            FILE_EXT="${FILE##*.}"
            
            echo "### COMPLETE FILE: $FILE (PR branch version)" >> "$OUTPUT_FILE"
            echo "\`\`\`$FILE_EXT" >> "$OUTPUT_FILE"
            git show "$PR_BRANCH":"$FILE" 2>/dev/null >> "$OUTPUT_FILE"
            echo "\`\`\`" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        else
            echo "### SKIPPED BINARY FILE: $FILE" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    else
        # File was deleted in PR branch
        echo "### FILE DELETED IN PR BRANCH: $FILE" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# Add review instructions
echo "## REVIEW INSTRUCTIONS" >> "$OUTPUT_FILE"
echo "Please review this PR with the following considerations:" >> "$OUTPUT_FILE"
echo "1. 📝 Code quality and best practices" >> "$OUTPUT_FILE"
echo "2. 🐛 Potential bugs or edge cases" >> "$OUTPUT_FILE"
echo "3. ⚡ Performance implications" >> "$OUTPUT_FILE"
echo "4. 🔒 Security concerns" >> "$OUTPUT_FILE"
echo "5. ✨ Suggested code improvements should be formatted as:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Line XX:** ✅/❌ Comment about the code" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Suggested Change:**" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "\`\`\`language" >> "$OUTPUT_FILE"
echo "// Code suggestion here" >> "$OUTPUT_FILE"
echo "\`\`\`" >> "$OUTPUT_FILE"

echo "Review file created: $OUTPUT_FILE"
