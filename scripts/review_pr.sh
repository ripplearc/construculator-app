#!/bin/bash

# =============================================================================
# PR REVIEW SCRIPT - AI CODE REVIEW WORKFLOW
# =============================================================================
#
# This script generates a comprehensive review document for AI analysis.
# Follow these steps to get detailed feedback on your code changes:
#
# STEP 1: Run the Review Script
# -----------------------------
# Basic usage - generates reviews/pr_review_for_cursor.txt
# ./scripts/review_pr.sh your-feature-branch main
#
# With custom output filename (saved under reviews/ automatically)
# ./scripts/review_pr.sh your-feature-branch main my_pr_review.txt
#
# Examples for different scenarios:
# ./scripts/review_pr.sh feat/user-authentication develop auth_review.txt
# ./scripts/review_pr.sh bugfix/login-validation main login_fix_review.txt
# ./scripts/review_pr.sh origin/feature-x upstream/main fork_review.txt
#
# STEP 2: Copy Content to Cursor for AI Review
# ---------------------------------------------
# 1. Open the generated review file (e.g., pr_review_for_cursor.txt)
# 2. Copy the entire content of the file
# 3. Paste it into Cursor and ask the AI to review it
# 4. The AI will analyze your code changes and provide detailed feedback
#
# STEP 3: Review the AI Analysis
# ------------------------------
# The AI will provide a comprehensive review that includes:
# - Changes Overview: Analysis of all modified files with statistics
# - GitHub-style Diffs: Detailed review of each file's changes
# - Review Instructions: Feedback based on the 4 review rules
# - Summary Table: Issues found that need your attention
#
# STEP 4: Use Markdown Preview
# ----------------------------
# 1. Use Markdown Preview in Cursor to view the AI's formatted response
# 2. Review the suggestions and recommendations
# 3. Copy the Review Summary table from the AI's response
#
# STEP 5: Update Your PR Description
# ----------------------------------
# Paste the AI-generated summary table into your PR description with your responses:
#
# | Issue Name        | Description                                                   | Status          | Notes                               |
# | ----------------- | ------------------------------------------------------------- | --------------- | ----------------------------------- |
# | Filename Typo     | fake_app_bootstarp.dart should be fake_app_bootstrap.dart | ✅ Addressed    | Renamed file to correct spelling    |
# | Missing Tests     | AuthService needs unit tests                                  | 📋 Future Story | Created YouTrack story: AUTH-123    |
# | Performance Issue | N+1 query in user list                                        | ❌ Disagree     | Query is optimized for our use case |
#
# STATUS OPTIONS:
# - ✅ Addressed: Issue has been fixed in this PR
# - 📋 Future Story: Issue will be addressed in a separate YouTrack story
# - ❌ Disagree: You disagree with the AI's assessment
# - 🔄 In Progress: Issue is being worked on but not complete
#
# NOTES REQUIREMENTS:
# - If You Agree and Have Addressed: Describe what changes were made
# - If You Agree but Needs Another Story: List the YouTrack story name for the refactor
# - If You Disagree: State the reason for disagreement with specific technical justification
#
# =============================================================================

# Check if enough parameters are provided
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 pr_branch base_branch [output_file]"
    echo "Example: $0 feature-branch main pr_review.txt"
    exit 1
fi

# Set variables from parameters
PR_BRANCH="$1"      # Branch with your changes
BASE_BRANCH="$2"    # Branch you want to merge into (target)

# Always write outputs under the reviews/ directory
OUTPUT_DIR="reviews"
mkdir -p "$OUTPUT_DIR"

if [ -n "$3" ]; then
    # If a name is provided, use only its basename under reviews/
    OUTPUT_FILE="$OUTPUT_DIR/$(basename "$3")"
else
    OUTPUT_FILE="$OUTPUT_DIR/pr_review_for_cursor.txt"
fi

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
# Filter out generated files and binary files
CHANGED_FILES=$(git diff --name-only "$BASE_BRANCH".."$PR_BRANCH" | grep -v -E '\.(g\.dart|freezed\.dart|gr\.dart|config\.dart|chopper\.dart|mocks\.dart)$' | grep -v -E '\.(png|jpg|jpeg|gif|svg|ico|webp|ttf|otf|woff|woff2|pdf|zip|tar|gz|rar|7z|exe|dll|so|dylib)$')

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


# =============================================================================
# REVIEW INSTRUCTIONS SECTION
# =============================================================================
echo "## REVIEW INSTRUCTIONS" >> "$OUTPUT_FILE"
echo "Please review this PR with the following considerations:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 1: DIGESTIBLE PR RULE
# =============================================================================
echo "### 📋 RULE 1: DIGESTIBLE PR RULE" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/551ccf7208a1dcf3f3edd27cac002214" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Size Classification (Production Code Only):**" >> "$OUTPUT_FILE"
echo "- XS: <50 lines | S: 50-100 lines | M: 100-200 lines | L: 200+ lines" >> "$OUTPUT_FILE"
echo "- **Action Required:** If PR is >M size, recommend breaking into smaller, focused PRs" >> "$OUTPUT_FILE"
echo "- **Focus:** Each PR should have single, clear purpose and pass tests independently" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 2: CLASS NAMING CONVENTION
# =============================================================================
echo "### 🏗️ RULE 2: CLASS NAMING CONVENTION" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/89f05e4f83e087f63148bbbb1d99a178" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Patterns:**" >> "$OUTPUT_FILE"
echo "- **UseCase:** \`VerbNounUseCase\` (single business operation)" >> "$OUTPUT_FILE"
echo "- **Service:** \`NounService\` (complex domain logic)" >> "$OUTPUT_FILE"
echo "- **Manager:** \`NounManager\` (stateful coordination)" >> "$OUTPUT_FILE"
echo "- **Repository:** \`NounRepository\` (data access abstraction)" >> "$OUTPUT_FILE"
echo "- **DataSource:** \`Local/RemoteNounDataSource\` (raw data handling)" >> "$OUTPUT_FILE"
echo "- **Helper Layer:** \`Noun(Formatter|Validator|Parser|Mapper|Converter)\`. **FORBIDDEN:** \`Helper\`, \`Util\` suffixes." >> "$OUTPUT_FILE"
echo "- **BLoC:** \`NounBloc\` + \`NounEvent\` + \`NounState\`" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:** Verify all new classes follow naming conventions and layer responsibilities" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 3: TEST DOUBLE PATTERN
# =============================================================================
echo "### 🧪 RULE 3: TEST DOUBLE PATTERN" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines, search: https://gist.github.com/ripplearcgit/89687b7414f62a8c042b16b52e9ceb0b" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Test real integration between components, only fake external dependencies" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Key Rules:**" >> "$OUTPUT_FILE"
echo "- ❌ **Avoid:** Fake everything approach (only fakes, no real implementations)" >> "$OUTPUT_FILE"
echo "- ✅ **Use:** Test Double pattern (real A + real B + fake external dependencies)" >> "$OUTPUT_FILE"
echo "- 🔒 **Forbidden:** Mock & Stub usage" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**When Testing Class A → Class B:**" >> "$OUTPUT_FILE"
echo "- Use **real implementation of B**" >> "$OUTPUT_FILE"
echo "- Swap out **B's external dependencies** with fakes (DB, Network, 3P libraries)" >> "$OUTPUT_FILE"
echo "- Test **real integration** and **real business logic**" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify tests use real implementations for business logic components" >> "$OUTPUT_FILE"
echo "- Check that only external dependencies (DB, network, 3P) are faked" >> "$OUTPUT_FILE"
echo "- Ensure BLoCs test real UseCases, UseCases test real Services, etc." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 4: UI & BUSINESS LOGIC SEPARATION
# =============================================================================
echo "### 🎨 RULE 5: UI & BUSINESS LOGIC SEPARATION" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines and code samples, search: https://gist.github.com/ripplearcgit/f190fecc8f7124e511cb01283f9fbc31" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Keep the UI 'dumb.' It should only handle layout, user input, and reflecting state." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Red Flags (Business Logic Pollution):**" >> "$OUTPUT_FILE"
echo "- ❌ **Guard Checks in UI:** Validating domain rules (e.g., 'is userId null?') before sending an event to the BLoC." >> "$OUTPUT_FILE"
echo "- ❌ **State Duplication:** Using \`setState\` to copy data from a BLoC/Repository into the Widget's local variables." >> "$OUTPUT_FILE"
echo "- ❌ **Manual Coordination:** Using one BLoC's listener to manually trigger an event in a different BLoC." >> "$OUTPUT_FILE"
echo "- ❌ **Transformation Logic:** Formatting raw data (dates, currency) or mapping errors to strings inside the Widget." >> "$OUTPUT_FILE"
echo "- ❌ **Navigation Decisions:** Deciding which route to take based on business conditions inside the UI." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Ensure the UI only dispatches 'Intents' (Events) and consumes 'States'." >> "$OUTPUT_FILE"
echo "- Verify that all validation, data fetching, and coordination live in BLoCs or UseCases." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 5: STREAM-BASED PERFORMANCE & LIFECYCLE
# =============================================================================
echo "### ⚡ RULE 6: STREAM-BASED PERFORMANCE & LIFECYCLE" >> "$OUTPUT_FILE"
echo "**Reference:** For detailed guidelines and code samples, search: https://gist.github.com/ripplearcgit/7818b412bf5fbe06269e0c3830e136f5" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Core Principle:** Manage stream lifecycles strictly to prevent memory leaks and minimize redundant network/CPU overhead." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Red Flags (Performance Risks):**" >> "$OUTPUT_FILE"
echo "- ❌ **Zombies:** Storing \`StreamControllers\` in a Map without using \`onCancel\` to close and remove them when listeners are gone." >> "$OUTPUT_FILE"
echo "- ❌ **Network Thrashing:** Triggering a full network re-fetch (e.g., \`getEstimations\`) every time a stream-based write occurs." >> "$OUTPUT_FILE"
echo "- ❌ **Event Flooding:** Forcing UI rebuilds on every stream tick without using \`distinct()\` or \`debounceTime()\` for high-frequency data." >> "$OUTPUT_FILE"
echo "- ❌ **Dangling Subscriptions:** Creating manual listeners in BLoCs or Services without cancelling them in the \`close()\` or \`dispose()\` method." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- Verify that all \`StreamControllers\` have a clear cleanup strategy." >> "$OUTPUT_FILE"
echo "- Check for 'Optimistic UI' patterns where local state is updated instead of a full server re-fetch." >> "$OUTPUT_FILE"
echo "- Ensure all BLoC stream subscriptions are cancelled during disposal." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 6: SELF-DOCUMENTING & CLEAN CODE (ANTI-AI ARTIFACTS)
# =============================================================================
echo "### 🧹 RULE 6: SELF-DOCUMENTING & CLEAN CODE" >> "$OUTPUT_FILE"
echo "**Core Principle:** Code must be expressive and clean. Use 'Code Documentation' to define contracts, but avoid 'Implementation Comments' to explain logic." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**✅ What to Keep (Code Documentation):**" >> "$OUTPUT_FILE"
echo "- **Public APIs:** Brief docstrings for Classes, Interfaces, and public Methods that explain *purpose* and *usage*." >> "$OUTPUT_FILE"
echo "- **Member Variables:** Documentation explaining the *intent* of a state variable if not immediately obvious." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**❌ Red Flags (Implementation Comments/Vibe Killers):**" >> "$OUTPUT_FILE"
echo "- **AI Residuals:** Instructional comments left by LLMs like \`// <-- ADD THIS\`, \`// implementation here\`, or \`// Fix: ...\`." >> "$OUTPUT_FILE"
echo "- **Step-by-Step Narratives:** Comments inside methods explaining *what* each line does. If the logic is complex, extract it into a named private method instead." >> "$OUTPUT_FILE"
echo "- **Obscure Naming:** Using generic names (\`data\`, \`info\`, \`val\`) that force a comment to explain what the variable actually holds." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Action Required:**" >> "$OUTPUT_FILE"
echo "- **Purge AI Artifacts:** Delete all instructional placeholders or AI-suggested annotations." >> "$OUTPUT_FILE"
echo "- **Refactor vs. Explain:** If you feel the urge to write a comment inside a function, refactor that logic into a descriptive variable or helper method instead." >> "$OUTPUT_FILE"
echo "- **Maintain Contracts:** Ensure docstrings accurately reflect the *behavior* of the code without detailing the *implementation*." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# RULE 7: GENERAL CODE REVIEW CRITERIA
# =============================================================================
echo "### 🔍 RULE 4: GENERAL CODE REVIEW CRITERIA" >> "$OUTPUT_FILE"
echo "1. 📝 Code quality and best practices" >> "$OUTPUT_FILE"
echo "2. 🐛 Potential bugs or edge cases" >> "$OUTPUT_FILE"
echo "3. ⚡ Performance implications" >> "$OUTPUT_FILE"
echo "4. 🔒 Security concerns" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# REVIEW OUTPUT FORMAT
# =============================================================================
echo "## REVIEW OUTPUT FORMAT" >> "$OUTPUT_FILE"
echo "Please provide your review in the following structured format:" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### 1. PR SUMMARY" >> "$OUTPUT_FILE"
echo "Provide a concise summary of what this PR is doing and its main objective." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "### 2. REVIEW SUMMARY TABLE" >> "$OUTPUT_FILE"
echo "If issues are found that need to be addressed, include the summary table below. If no issues are found, omit the table entirely." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# =============================================================================
# REVIEW SUMMARY TABLE
# =============================================================================
echo "## REVIEW SUMMARY" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**IMPORTANT:** Only include this table if you find issues that need to be addressed. If the PR has no outstanding issues, delete this entire section." >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| Issue Name | Description | Status | Notes |" >> "$OUTPUT_FILE"
echo "|------------|-------------|--------|-------|" >> "$OUTPUT_FILE"
echo "| [Brief issue name] | [Detailed description of the issue] | [Author to fill out] | [Author to fill out] |" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Status Options (for PR Author to fill out - NOT for LLM):**" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "**Notes Requirements (for PR Author to fill out - NOT for LLM):**" >> "$OUTPUT_FILE"
echo "- **If Author Disagree:** State the reason for disagreement" >> "$OUTPUT_FILE"
echo "- **If Agree and Have Addressed:** Describe what changes were made" >> "$OUTPUT_FILE"
echo "- **If Agree but Needs Another Story:** List the YouTrack story name for the refactor" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Review file created: $OUTPUT_FILE"
