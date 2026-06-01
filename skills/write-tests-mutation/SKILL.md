---
name: write-tests-mutation
description: |
  Stage 4: Testing - GATED - Run mutation testing for complex business logic.
  Validates test quality by introducing bugs and checking if tests catch them.

  ⚠️ GATED: Only for code with at least three conditional branches, complex mathematical calculations, or significant data transformation logic (pagination, filtering, sorting).

  Trigger: "run mutation tests", "mutation testing", "check mutation score"

disable-model-invocation: false
---

# Write Tests Mutation Skill

**Verb:** Run mutation testing to validate test quality for logic-heavy code.

⚠️ **GATED** — Only for complex business logic with 3+ conditional branches.

## Gate Check

| ✅ Run Mutation Testing | ❌ Skip |
|------------------------|---------|
| Complex conditionals (3+ branches) | Simple CRUD operations |
| Mathematical calculations | UI/presentation code |
| Data transformation logic (pagination, filtering, sorting) | Generated code |
| Critical decision paths (authentication, authorization, payment) | Simple getters/setters |

## Logic Classification

**Critical Logic** (requires 85% mutation score):
- Authentication/authorization systems
- Payment processing and financial calculations
- Access control and data validation affecting security/correctness

**Non-Critical Logic** (70% mutation score acceptable):
- Display formatting, sorting/filtering for UI
- Non-essential calculations and secondary features

## Running Mutation Tests

**Step 1: Create mutation config**

Copy `test/features/estimations/mutations/add_cost_estimation_usecase.xml` as a template. Key attributes:
- `timeout` on `<command>` — **per-mutation timeout in seconds**; set to ~2× your normal test run time (prevents infinite loops caused by mutations)
- `threshold failure` — `85` for critical logic, `70` for non-critical
- `<exclude>` — exclude logger calls and try/catch blocks (noise mutations)

Location: `test/features/{feature}/mutations/{file}_mutations.xml`

**Step 2: Run**

```bash
dart run mutant --config test/features/{feature}/mutations/{file}_mutations.xml
```

**Step 3: Check the score**

Read `mutation-test-report/mutation-test-report.html` — it is small (~8KB) and contains the overall score, detected/total counts, and quality rating.

If score ≥ 85% → done. If score < 85%, grep each detail file in `mutation-test-report/lib/` for `Undetected` to identify survived mutation IDs. Add a test for each that asserts the specific behavior the mutation changes, then re-run.

⚠️ Do NOT read per-file detail HTML files in full — they can be 75KB+.

## Score Targets

| Score | Status | Action |
|-------|--------|--------|
| 85–100% | ✅ Pass | Ship |
| 70–84% | ⚠️ Acceptable | Non-critical logic only |
| <70% | ❌ Insufficient | Extract survived mutations and add tests |

## Typical Targets

**✅ Run for:**
- `lib/features/**/domain/usecases/*.dart`
- `lib/features/**/domain/services/*.dart`
- `lib/features/**/data/repositories/*_impl.dart` — if contains logic
- `lib/features/**/data/data_source/*.dart` — if contains transformation logic

**❌ Skip:**
- `lib/features/**/presentation/**`
- `lib/features/**/data/models/**`
- Generated code

## Best Practices

1. Run during PR review, not on every commit (mutation testing is slow)
2. Target changed files only
3. Include mutation score in PR description
4. Focus on critical paths: auth, authorization, payment, validation
5. Read `mutation-test-report.html` for score; grep detail HTML for survived mutation IDs — never read detail files in full

## References

- **RULE_13:** `skills/rules/13-mutation-testing.md`
- **Example config:** `test/features/estimations/mutations/add_cost_estimation_usecase.xml`
- **Package:** `dart pub global activate mutant`
