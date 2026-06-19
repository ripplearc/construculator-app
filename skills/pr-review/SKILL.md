---
name: pr-review
description: |
  Modular PR review for Flutter/Dart changes. Auto-detects which rules apply to
  each changed file, applies the full rule set in skills/rules/ (RULE_1–RULE_15),
  and returns a copy-paste-ready markdown PR description + review table.

  Use when a user asks to review a PR, review a branch, compare branches, or
  check naming, CoreUI, testing, streams, localization, accessibility, logging,
  or UI/business separation.

  Trigger phrases: "review this PR", "review my PR", "review feat/X to main",
  "check my branch", "code review", "analyze my changes".
disable-model-invocation: false
allowed-tools: Bash Read Grep Write
---

# PR Review Skill

Reviews a branch diff against a base, routes each changed file to only the rules
that apply, and reports findings. Default output is a markdown document ready to
paste into a PR (see [Output](#output)).

## Rules

The full rule set lives in `skills/rules/`. Each rule file owns its detection
patterns (its `Detective` section), severity levels, and fix guidance — load a
rule only when it's routed to a changed file.

| Rule | Title | Applies to |
|------|-------|-----------|
| RULE_1 | Digestible PR | Production-code diff size (PR-level) |
| RULE_2 | Naming & Abstraction | `lib/**/*.dart` |
| RULE_3 | Test Double Pattern | `test/**/*.dart` |
| RULE_4 | CoreUI Components | `**/presentation/`, `lib/app/` |
| RULE_5 | UI / Business Separation | `**/presentation/`, `lib/app/` |
| RULE_6 | Stream Lifecycle | Stream-owning `lib/**` (Repo/DataSource/BLoC/Service) |
| RULE_7 | Self-Documenting Code | `lib/**/*.dart` |
| RULE_8 | Widget Test Finders | `test/**/widgets/`, `testWidgets(` |
| RULE_9 | Unit Test Behavior | `test/features/**` unit tests |
| RULE_10 | Localization | `**/presentation/`, `lib/app/` |
| RULE_13 | Mutation Testing | **Gated:** logic-heavy domain/data files |
| RULE_14 | Accessibility | **Gated:** user-facing UI + `*_a11y_test.dart` |
| RULE_15 | Sentry Logging | `lib/**` using `AppLogger` |

`RULE_11`→`RULE_2` and `RULE_12`→`RULE_5` are deprecated; if a user passes them,
map transparently and note it in `rules_skipped`.

## Input

| Field | Required | Default | Notes |
|-------|----------|---------|-------|
| `pr_branch` | yes | — | branch with changes |
| `base_branch` | no | `main` | target branch |
| `rules` | no | all | force a subset, e.g. `["RULE_2","RULE_6"]` |
| `output_format` | no | `markdown` | `markdown` \| `json` \| `both` |
| `output_dir` | no | `reviews/` | directory (repo-root-relative) the `.md` review file is written to |
| `max_file_size_kb` | no | `100` | skip larger files (1–1000) |

On missing/invalid input, return an error object (see [Errors](#errors)).

## Workflow

1. **Collect** changed files — pipe `{"pr_branch","base_branch"}` into
   `scripts/collect_changes.sh`. It already excludes generated (`*.g.dart`,
   `*.freezed.dart`, …) and binary files, so every returned file is relevant.
   No files → return empty issues with all rules in `rules_skipped`.

2. **Route** each file to rules using the *Applies to* column above. Path-based
   buckets come from `scripts/filter_files.sh`; content-derived buckets
   (`stream_owning`, `logic_heavy`, `logger_using`) are confirmed by grepping the
   file (e.g. `grep -lE "StreamController|\.listen\(" …`, `grep -l "AppLogger" …`).
   RULE_1 always runs once over the production-code diff size.

3. **Gate** RULE_13 and RULE_14:
   - RULE_13 only if a logic-heavy file (3+ branches / math / data transforms)
     changed — else skip: `"No logic-heavy code changed"`.
   - RULE_14 only if an interactive presentation file changed; then require a
     matching `*_a11y_test.dart` update and flag if missing — else skip:
     `"No user-facing UI changed"`.
   If the user passed `rules`, apply only those (after the 11→2 / 12→5 mapping);
   record the rest in `rules_skipped` with reason `"User specified rules: [...]"`.

4. **Apply** each routed rule: `cat` its module from `skills/rules/`, read the
   file (`git show "$PR_BRANCH:path"`), get diff context via
   `scripts/generate_diff.sh`, and use the rule's own detection patterns. Record
   each violation as an issue: `file`, `line`, `snippet` (3 lines context),
   `severity`, `suggested_fix`, and `references` (the rule module + any relevant
   `skills/references/*.md`).

5. **Compile** statistics (counts by severity and rule) and build the output
   object below.

Any rule with an empty routed bucket is skipped with a reason. Cache file
contents to avoid re-reading.

## Output

The findings are modeled as JSON matching `schemas/output.schema.json`:
`summary`, `metadata`, `issues[]`, `rules_applied`, `rules_skipped[]`,
`next_steps`, `statistics`.

Each issue: `{ id, name, description, rule, severity, file, line, snippet,
suggested_fix, references[] }` with severity ∈ `critical|major|minor|suggestion`.

**`markdown` (default) / `both`** — render the JSON as one self-contained
document the user pastes straight into the PR. Output *only* the markdown (no
outer code fence, no JSON), derive every value from the computed issues, and
leave `Status`/`Notes` blank for the author. With zero issues, omit the table
and write `✅ No issues found — all applied rules passed.` With `both`, emit the
JSON, then `---`, then the markdown. With `json`, skip the markdown.

````markdown
# PR Review: <pr_branch> → <base_branch>

## 📝 PR Description

<2–4 plain-language sentences on what this PR does and why — no rule jargon.>

**Type:** <Feature | Bugfix | Refactor | Chore | Test | Docs> ·
**Size:** <XS | S | M | L> (<N> production lines) ·
**Rules applied:** <rule IDs>

### What changed
- <key change tied to a concrete file/feature>
- <key change>

---

## 🔍 Review Summary

> Found <N> issue(s): <X> 🔴 critical · <Y> 🟠 major · <Z> 🟡 minor · <W> 🔵 suggestion — across <M> file(s).

| # | Issue | Severity | Location | Description | Suggested Fix | Status | Notes |
|---|-------|----------|----------|-------------|---------------|--------|-------|
| 1 | <name> | 🔴 Critical | `<file>:<line>` | <what & why> | <fix> | | |

**Status (author fills):** ✅ Addressed · 📋 Future Story (add YouTrack ID) ·
❌ Disagree (justify) · 🔄 In Progress

<!-- Skipped: RULE_X (reason), RULE_Y (reason) -->
````

Sort rows by severity (critical→suggestion) then file; number the `#` column;
collapse newlines and escape `|` as `\|` in cells; omit `:<line>` for PR-level
issues (RULE_1); build the blockquote from `statistics.by_severity`.

### Saving the review file

Whenever the output includes markdown (`markdown` or `both`), **also persist it to a
file** — don't only print it. Steps:

1. Ensure the output directory exists: `mkdir -p "$OUTPUT_DIR"` (default
   `reviews/`, repo-root-relative).
2. Build a slug from the branches by replacing every non-alphanumeric character
   (including `/`) with `-`: `<pr_slug>__to__<base_slug>.md`. Example:
   `feat/power-sync-wrappers` → `feat-power-sync-wrappers`, base
   `feat/wire-powersync` → `feat-wire-powersync`, so the file is
   `reviews/feat-power-sync-wrappers__to__feat-wire-powersync.md`.
3. Write the exact rendered markdown document (the same content described above,
   no outer code fence) to that path with the `Write` tool, overwriting any
   existing file for the same branch pair.
4. Report the written file path to the user, then show the markdown inline.

For `output_format: json` (no markdown), skip file creation. The `reviews/`
directory is a working artifact — assume it may be git-ignored; create it if
missing rather than failing.

## Errors

Scripts and this skill return JSON on failure:
`{ "error", "code", "details?", "suggestions" }`.

Codes: `MISSING_REQUIRED_FIELD`, `INVALID_ENUM`, `INVALID_BRANCH`, `GIT_ERROR`,
`PARSE_ERROR`, `FILE_NOT_FOUND`. On a git/branch failure, return the branch names
to verify; oversized files are skipped and noted in `rules_skipped`; a missing
rule module means the file was likely deleted.

## Notes

- Scripts are idempotent. The legacy monolithic `scripts/review_pr.sh` is
  retired; keep it only as a historical reference for detection patterns.
- Always record gate results (RULE_13/RULE_14) in `rules_applied` or
  `rules_skipped` so coverage is auditable.

