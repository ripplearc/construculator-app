---
name: pr-review
description: |
  Modular PR review skill for Flutter/Dart changes.
  Use when a user asks for a PR review, code review, branch comparison, or
  asks to check CoreUI, localization, UI/business separation, or test quality.

  This skill starts with a proof of concept for RULE_4, RULE_5, and RULE_10,
  while preserving the existing scripts/review_pr.sh workflow during migration.

  Trigger phrases: "review this PR", "review my PR", "review feat/X to main",
  "check my branch", "code review", "analyze my changes"

disable-model-invocation: false
allowed-tools: Bash Read Grep
---

# PR Review Skill

This skill reviews PR changes in a structured way and returns findings in JSON.
It follows a progressive disclosure model:

1. Use `scripts/collect_changes.sh` to gather changed files.
2. Auto-detect applicable rules based on file types.
3. Use `scripts/generate_diff.sh` to fetch diffs for analysis.
4. Apply rules to identify issues and violations.
5. Return structured JSON with findings.

## Current POC Scope

This migration starts with three high-signal rules:

- RULE_4: CoreUI Components Usage
- RULE_5: UI & Business Logic Separation
- RULE_10: Localization Usage

## Input Contract

Required:
- `pr_branch`: branch containing changes (e.g., "feat/login")

Optional:
- `base_branch`: target branch, defaults to `main`
- `rules`: optional list of rule IDs to force (e.g., ["RULE_4", "RULE_5"])
- `output_format`: `json`, `markdown`, or `both`, defaults to `json`
- `max_file_size_kb`: skip files larger than this (1-1000), defaults to 100

## Agent Execution Workflow

### Step 1: Parse and Validate Input

Extract parameters from user request and validate against input schema:

```
- pr_branch (required): string, non-empty
- base_branch (optional): string, defaults to "main"
- rules (optional): array of ["RULE_4", "RULE_5", "RULE_10"]
- output_format (optional): enum [json, markdown, both], defaults to "json"
- max_file_size_kb (optional): number 1-1000, defaults to 100

If any required field is missing or invalid, return error JSON:
{
  "error": "Field X is required/invalid",
  "code": "MISSING_REQUIRED_FIELD" | "INVALID_ENUM" | "PARSE_ERROR",
  "suggestions": ["How to fix"]
}
```

### Step 2: Collect Changed Files

Run `bash skills/pr-review/scripts/collect_changes.sh` with input:

```bash
echo '{"pr_branch": "'"$PR_BRANCH"'", "base_branch": "'"$BASE_BRANCH"'"}' | \
  bash skills/pr-review/scripts/collect_changes.sh
```

Expected output:
```json
{
  "files": [
    {"path": "lib/features/auth/login.dart", "status": "M"},
    {"path": "lib/features/auth/login_screen.dart", "status": "A"},
    ...
  ]
}
```

**Handle errors:**
- If script returns `{"error": "..."}`, abort and return error to user
- If no files changed, return empty issues list with `rules_skipped` = all rules

### Step 3: Filter Applicable Files

Filter changed files to only presentation files (these are the only files applicable to POC rules):

```bash
echo "{\"files\": [$FILES_JSON], \"pattern\": \"lib/features/**/presentation/\"}" | \
  bash skills/pr-review/scripts/filter_files.sh
```

Also filter `lib/app/presentation/` files:

```bash
echo "{\"files\": [$REMAINING_FILES], \"pattern\": \"lib/app/presentation/\"}" | \
  bash skills/pr-review/scripts/filter_files.sh
```

Merge and deduplicate the two filter outputs into a single presentation file list before continuing. Example (pseudo):

```bash
# outputA and outputB are JSON arrays returned by filter_files.sh
# merge, dedupe:
jq -s 'add | unique_by(.path)' outputA.json outputB.json > presentation_files.json
```

Expected output:
```json
{
  "files": [
    {"path": "lib/features/auth/presentation/login_screen.dart"},
    {"path": "lib/app/presentation/app_widget.dart"}
  ]
}
```

**Result:** Reduced file set ready for rule application. If no presentation files, `rules_skipped` = all 3 rules.

### Step 4: Auto-Detect Applicable Rules

Based on changed file paths, determine which rules to apply:

**Rule Selection Logic:**

```
For filtered presentation files (already filtered in Step 3):
  → Always apply RULE_4 (CoreUI Components)
  → Always apply RULE_5 (UI/Business Logic Separation)
  → Always apply RULE_10 (Localization)

If user specified --rules argument:
  → Override and apply only specified rules

If no presentation files were filtered:
  → All 3 rules are skipped with reason "No presentation files changed"
```

**Example:**
- Input: 14 files changed across project
- After filtering (Step 3): 2 presentation files
- Rules applied: [RULE_4, RULE_5, RULE_10]
- All 3 rules run against both files

**If user overrides with specific rules:**
```
Input: {"rules": ["RULE_4"]}
→ Only RULE_4 runs on filtered presentation files
→ RULE_5, RULE_10 tracked as skipped: {"rule": "RULE_5", "reason": "User specified rules: [RULE_4]"}
```

### Step 5: Load Rule Modules

For each applicable rule, load the rule file and extract detection patterns:

```bash
cat skills/pr-review/rules/04-coreui-components.md
cat skills/pr-review/rules/05-ui-business-separation.md
cat skills/pr-review/rules/10-localization.md
```

Each rule module provides:
- Detection patterns (regex or semantic patterns)
- Severity levels (critical, major, minor, suggestion)
- Suggested fixes
- References and examples

### Step 6: Apply Rules to Filtered Files

For each filtered presentation file and applicable rule:

**6a. Read file content** (if not already cached):
```bash
git show infra/agentic-skills:lib/features/auth/presentation/login_screen.dart
```

**6b. Generate diff** for context:
```bash
echo '{
  "pr_branch": "infra/agentic-skills",
  "base_branch": "main",
  "file": "lib/features/auth/presentation/login_screen.dart",
  "context_lines": 3
}' | bash skills/pr-review/scripts/generate_diff.sh
```

**6c. Search for violations** using grep patterns defined in rule:

For RULE_4, search for:
- `EdgeInsets\.(all|symmetric|only)\((?!CoreSpacing)` → Hardcoded spacing
- `Icons\.` → Material icons (not CoreUI)
- `ElevatedButton|TextFormField|AppBar` → Material components
- `Colors\.` → Hardcoded colors

**6d. Extract issue details** for each violation found:
- File path
- Line number(s)
- Snippet with context (3 lines before/after)
- Severity (based on rule)
- Suggested fix
- References to documentation

**6e. Compile issue object:**
```json
{
  "id": "RULE_4-001",
  "name": "Hardcoded spacing value",
  "description": "EdgeInsets.all(24.0) should use CoreSpacing constant",
  "rule": "RULE_4",
  "severity": "major",
  "file": "lib/features/auth/presentation/login_screen.dart",
  "line": 42,
  "snippet": "Padding(\n  padding: EdgeInsets.all(24.0),  // ← Issue here\n  child: ...",
  "suggested_fix": "Replace EdgeInsets.all(24.0) with EdgeInsets.all(CoreSpacing.space24)",
  "references": [
    "skills/pr-review/rules/04-coreui-components.md",
    "skills/pr-review/references/coreui-api.md#spacing"
  ]
}
```

### Step 7: Compile Statistics

Count issues by severity and rule:

```json
{
  "statistics": {
    "total_issues": 5,
    "by_severity": {
      "critical": 0,
      "major": 2,
      "minor": 2,
      "suggestion": 1
    },
    "by_rule": {
      "RULE_4": 3,
      "RULE_5": 2,
      "RULE_10": 0
    },
    "files_analyzed": 2,
    "files_with_issues": 2
  }
}
```

### Step 8: Generate Final Output

Compile all issues, metadata, and statistics into output JSON matching `schemas/output.schema.json`:

```json
{
  "summary": "Found 5 issues (2 major, 2 minor, 1 suggestion) in 2 files",
  "metadata": {
    "pr_branch": "feat/auth",
    "base_branch": "main",
    "skill_version": "1.0.0-poc",
    "timestamp": "2026-04-30T18:24:03Z",
    "files_changed": 2,
    "rules_applied": ["RULE_4", "RULE_5", "RULE_10"]
  },
  "issues": [...],
  "rules_applied": ["RULE_4", "RULE_5", "RULE_10"],
  "rules_skipped": [...],
  "next_steps": [
    "Replace hardcoded spacing with CoreSpacing constants",
    "Move business logic out of LoginScreen widget",
    "Add localization for user-facing strings"
  ],
  "statistics": {...}
}
```

If `output_format` is "markdown" or "both", also generate markdown output.

## Error Handling

All scripts return JSON on success or error. Handle these error codes:

```json
{
  "error": "Human-readable message",
  "code": "ERROR_CODE",
  "details": {"field": "...", "expected": "...", "received": "..."},
  "suggestions": ["How to fix"]
}
```

**Error codes:**
- `MISSING_REQUIRED_FIELD` - Required input missing
- `INVALID_ENUM` - Invalid enum value
- `INVALID_BRANCH` - Branch doesn't exist
- `GIT_ERROR` - Git command failed
- `PARSE_ERROR` - Failed to parse JSON
- `FILE_NOT_FOUND` - File doesn't exist in branch

**Agent behavior on error:**
- If schema validation fails → Return error, ask user to correct input
- If git command fails → Return error with branch names to verify
- If file is too large (> max_file_size_kb) → Skip file, log in rules_skipped
- If rule module is missing → Return error, file likely deleted

## File Routing

**RULE_4, RULE_5, RULE_10 trigger on:**
- ✅ `lib/features/**/presentation/*.dart`
- ✅ `lib/app/presentation/*.dart`
- ❌ `test/` (test files skip all rules)
- ❌ `lib/**/*.g.dart`, `*.freezed.dart`, etc. (generated code)

## Output Shape

Return a JSON object matching `schemas/output.schema.json` with:

- `summary` - Human-readable summary of findings
- `metadata` - Execution metadata (branches, timestamp, version)
- `issues` - Array of issue objects
- `rules_applied` - List of rules that ran
- `rules_skipped` - List of rules with skip reason
- `next_steps` - Suggested next actions
- `statistics` - Issue counts by severity/rule

## Notes

- Keep the existing `scripts/review_pr.sh` available during the transition.
- Expand the rule set incrementally after the POC is validated on real PRs.
- All scripts are idempotent and can be run multiple times without side effects.
- Agent should cache file contents to minimize disk I/O.

- Deprecation note: `scripts/review_pr.sh` is kept for backward compatibility during
  the POC. Remove or retire the script after the POC has been validated on several
  real PRs (for example, "remove after POC is validated on N real PRs or by YYYY-MM-DD").
