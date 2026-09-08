# RULE 1: Digestible PR

## Name
Digestible PR

## Category
Code Review & PR Structure

## Severity Levels
- Major: PR exceeds Medium size (>200 lines of production code)
- Minor: PR is at Medium size (100-200 lines) but could be split logically
- Suggestion: Consider breaking larger PRs for easier review

## Description

Pull requests should be focused, digestible, and independently testable. Large PRs are harder to review thoroughly, increase risk of bugs slipping through, and slow down the review process.

## Applicability

This rule applies during PR creation and review. It is primarily used by review agents to flag oversized PRs.

---

## For Review Agents (Detective)

### Size Classification (Production Code Only)

**Size Thresholds:**
- **XS:** < 50 lines
- **S:** 50-100 lines
- **M:** 100-200 lines
- **L:** 200+ lines

**What Counts:**
- ✅ Production code (lib/**/*.dart, excluding generated files)
- ❌ Test files (test/**/*.dart)
- ❌ Generated files (*.g.dart, *.freezed.dart, *.gr.dart, *.config.dart, etc.)
- ❌ Documentation, markdown, config files

### Detection Pattern

```bash
# Count production code changes only
git diff --stat $BASE_BRANCH..$PR_BRANCH -- 'lib/**/*.dart' \
  ':(exclude)*.g.dart' \
  ':(exclude)*.freezed.dart' \
  ':(exclude)*.gr.dart' \
  ':(exclude)*.config.dart' \
  ':(exclude)*.chopper.dart' \
  ':(exclude)*.mocks.dart' | tail -1
```

### Action Required

**If PR is >M size (200+ lines):**
- Flag as **Major** severity
- Recommend breaking into smaller, focused PRs
- Suggest logical split points (by feature, layer, or file)

**Example Split Suggestions:**
- Feature-based: "Split into: 1) Domain layer changes, 2) Presentation layer changes"
- File-based: "Move EstimationRepository changes to separate PR"
- Concern-based: "Separate refactoring from new feature"

### Key Principle

Each PR should have a **single, clear purpose** and **pass tests independently**.

**Bad Example:**
- PR contains: New authentication flow + Refactor EstimationBloc + Fix currency formatter bug
- **Why bad:** Three unrelated concerns, hard to review, risky to merge

**Good Example:**
- PR 1: New authentication flow (Auth domain + presentation + tests)
- PR 2: Refactor EstimationBloc (single refactor, all tests pass)
- PR 3: Fix currency formatter bug (isolated bug fix)

---

## For Coding Agents (Prescriptive)

### When Planning Implementation

Before starting work, consider:

**Decision Gate:**
```
Will this change require >200 lines of production code?
  → YES: Plan to split into multiple PRs
  → NO: Proceed with single PR
```

**How to Split Work:**

1. **By Architecture Layer:**
   - PR 1: Domain layer (UseCases, Repositories, Models)
   - PR 2: Data layer (Repository impl, DataSources)
   - PR 3: Presentation layer (BLoC, UI)

2. **By Feature Scope:**
   - PR 1: Core feature (happy path only)
   - PR 2: Error handling and edge cases
   - PR 3: Loading states and optimizations

3. **By Dependency:**
   - PR 1: Foundation changes (shared utilities, models)
   - PR 2: Feature implementation (depends on PR 1)
   - PR 3: UI polish (depends on PR 2)

### Anti-Pattern: "Big Bang" PRs

❌ **Avoid:**
- Combining refactor + new feature
- Touching multiple unrelated features
- "While I'm here" changes

✅ **Prefer:**
- One feature per PR
- Refactors as separate PRs
- Related changes only

---

## References
- [GitHub Gist: Digestible PR Rule](https://gist.github.com/ripplearcgit/551ccf7208a1dcf3f3edd27cac002214)

## Notes

This rule is primarily for **PR review and planning**. Coding agents should use it during planning to avoid creating oversized PRs, while review agents use it to flag existing large PRs.
