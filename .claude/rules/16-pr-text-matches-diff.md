# RULE 16: PR Text Matches the Diff

## Name
PR Text Matches Diff

## Category
Code Review & PR Structure

## Severity Levels
- **Major:** A sentence in the PR text is not true for the current diff (a file, line count, test or behavior it names is missing or different)
- **Minor:** A count or name is close but out of date (e.g. "~120 lines" when the diff has 160)
- **Suggestion:** Something in the diff is worth naming but the PR text does not mention it

## Description

The PR text is read by the reviewer first and by anyone who finds the PR later. After a few review rounds it often still describes the first version: it names files that changed or were dropped, line counts that are wrong, tests that were renamed, or behavior the code no longer has. The reviewer then checks claims that are not true.

**Core Principle:** Every sentence in the PR text that states a fact about the change must be true for the diff as it is now.

## Applicability

**PR-level, runs once per review, and only when `pr_number` is given.** Without `pr_number` the skill cannot read the PR text, so the rule is skipped with reason `"No pr_number given"`.

The PR text is the `title` and `body` returned by `scripts/collect_pr_text.sh`. The diff is `$BASE_BRANCH..$PR_BRANCH`.

---

## For Coding Agents (Prescriptive)

### When to update the PR text

After every push that changes the diff, re-read the PR text and fix any sentence the new commit made untrue. Most often:

| The commit did this | Fix this in the PR text |
|---|---|
| Added, renamed or removed a file | The file list / "What changed" bullets |
| Changed production line count | The size line — quote rule 01's insertions count, not GitHub's +/- |
| Renamed, added or removed a test | Test names in the testing section |
| Changed how something behaves (a review fix) | The sentence describing that behavior |
| Took a different approach than first planned | The summary — describe what the code does now, not the history |

### Write claims that can be checked

- Name files by path: `lib/src/components/chips/core_chip.dart`, not "the chip file".
- Name tests by their exact `test(` / `testWidgets(` string.
- Give counts as numbers taken from git, not from memory.
- State decisions, not open questions.

---

## For Review Agents (Detective)

### Inputs

```bash
# PR text
echo "{\"pr_number\": $PR_NUMBER}" | bash .claude/skills/pr-review/scripts/collect_pr_text.sh

# What the diff really contains
git diff --name-status "$BASE_BRANCH".."$PR_BRANCH"
git diff --stat "$BASE_BRANCH".."$PR_BRANCH"
# Production insertions, same command as rule 01 (Digestible PR)
```

### Workflow

```
1. Split the PR title and body into sentences / bullets / table rows.
2. Drop the ones that state no fact about this change:
   template headings, unticked or ticked checklist boxes, links to tickets,
   "why" paragraphs about the problem (not the code), and the attribution footer.
3. Sort each remaining claim into one of the four kinds below and check it.
4. Each claim the diff does not support is ONE finding. Quote the sentence and
   say what the diff shows instead.
```

### What to check

| Kind of claim | Example sentence | How to check | Not true when |
|---|---|---|---|
| **File name** | "Adds `test/.../foo_test.dart`" | `git diff --name-status` — status letter must match the verb (A = adds, M = changes, D = removes, R = renames) | The file is not in the diff, or the status is different |
| **Line count / size** | "Size: S (64 production lines)" | Rule 01's insertions count | The number is different. Off by ≤10% → Minor; more → Major |
| **Test name** | "`shows the hint when empty` covers …" | `git grep -n "test(\|testWidgets(" "$PR_BRANCH" -- <test files in diff>` and look for the exact string | No test in the PR's files has that name |
| **Behavior** | "Tapping × now clears the field and keeps focus" | Read the diff hunks of the file that owns the behavior (`scripts/generate_diff.sh`) and the test that proves it | The code does something else, or the behavior was reverted in a later commit |

For a stacked PR, the base is the parent branch, not `main`. Check claims against `parent..PR`, otherwise the parent's files look like they belong to this PR.

### Finding shape

- `file`: the file the sentence is about. Use `PR description` when it names no file.
- `line`: leave empty (PR-level).
- `snippet`: the exact sentence from the PR text.
- `description`: what the diff shows, e.g. "PR text says `foo_test.dart` was added, but the diff has no such file".
- `suggested_fix`: the corrected sentence.

### Common Violations

| ❌ PR text says | Diff shows | Severity |
|---|---|---|
| "Adds `chip_a11y_test.dart`" | No such file in `--name-status` | Major |
| "Size: XS (32 lines)" | Rule 01 counts 140 insertions | Major |
| "Size: S (90 lines)" | Rule 01 counts 96 insertions | Minor |
| "Test `closes on Escape` covers the key path" | Test was renamed to `closes when Escape is pressed` | Major |
| "The toast stays until dismissed" | Code now auto-dismisses after 4 s | Major |
| "Also touches `core_button.dart`" | That change was moved to another PR | Major |
| — (nothing) | A new public widget is added | Suggestion |

### Review Questions

1. Would a reviewer who trusts this sentence look for something that is not there? → Major.
2. Does a count in the text come from git, or was it typed from memory? → re-count.
3. Did a later commit in the branch undo what the text describes? → check the newest hunk, not the first.

---

## Summary: Suggested Fixes

1. Re-read the PR text after every push that changes the diff.
2. Fix file lists, counts and test names from git output, not memory.
3. Describe what the code does now; leave the history to the commits.
4. For stacked PRs, describe only this PR's diff against its parent.

## References

- `scripts/collect_pr_text.sh` (reads the PR text)
- Related: Digestible PR (the production line count)
