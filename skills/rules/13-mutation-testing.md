# RULE 13: Mutation Testing for Logic-Heavy Changes

## Name
Mutation Testing

## Category
Testing - Quality Assurance

## Severity Levels
- **Critical:** Logic-heavy PR with <80% mutation score and surviving mutants in critical paths
- **Major:** Complex business logic added without mutation testing
- **Minor:** Mutation testing not run on logic-heavy components
- **Suggestion:** Consider mutation testing for branches with 3+ conditional paths

## Description

PRs that introduce or modify complex business logic, mathematical calculations, or data transformations are validated with mutation testing — introducing bugs (mutants) and checking whether tests catch them. This validates that tests verify *correctness*, not just line coverage.

**Core Principle:** mutation testing finds gaps in your tests that code coverage cannot detect.

## Applicability

**GATED.** Apply only to:
- Files with 3+ conditional branches
- Mathematical calculations / algorithms
- Data transformation logic (pagination, filtering, sorting)
- Critical decision paths (auth, authorization, payment)

**Do NOT apply to:** simple CRUD, UI/presentation, generated code.

**Typical targets:** `lib/features/**/domain/usecases/*.dart`, `lib/features/**/domain/services/*.dart`, `lib/features/**/data/repositories/*_impl.dart`, `lib/features/**/data/data_source/*.dart` (if it contains logic).

---

## For Coding Agents (Prescriptive)

### Decision Gate

```
Does the file contain logic-heavy code?

├─ Complex conditionals (3+ branches)?  → Run mutation testing
├─ Mathematical calculations?           → Run mutation testing
├─ Data transformation logic?           → Run mutation testing
├─ Critical decision paths?             → Run mutation testing
└─ Simple CRUD / UI code?               → Skip
```

### What Mutation Testing Does

The tool changes one operator/branch/return at a time (a "mutant") and re-runs tests. If tests still pass, the mutant **survived** → there's a gap. If tests fail, the mutant was **killed** → tests cover that behavior. Equivalent mutants (no behavior change, e.g. `&&` → `&` with no short-circuit difference) cannot be killed and are excluded.

### Score Thresholds

- **Critical paths** (auth, authorization, payment, financial calculations, security-relevant validation): **≥ 85%**.
- **Non-critical logic** (display formatting, UI-side sorting/filtering, secondary features): **≥ 70%** acceptable.
- **< 60% on any logic-heavy file:** insufficient — add tests for surviving mutants and re-run.

### Mutation Categories to Hand-Author

The repo runs `mutation_test` with `--no-builtin`, so all mutations are explicit `<regex pattern="…" id="…"><mutation text="…"/></regex>` rules in the XML config — not auto-generated. Cover at least these categories per file:

| Category | Example rule (regex → mutation) | What it Tests |
|---|---|---|
| **Conditional boundary** | `>` → `>=` | Boundary conditions |
| **Negation** | `if (x)` → `if (!x)`, `isEmpty` → `isNotEmpty` | Boolean logic |
| **Arithmetic** | `+` → `-`, `*` → `/` | Calculations |
| **Return value** | `return Right(x)` → `return Left(UnexpectedFailure())` | Failure / success paths |
| **Constant** | `0.0` → `10.0`, `MarkupType.overall` → `MarkupType.perAssembly` | Magic values / enum cases |
| **Skip statement / null-replace** | `value = compute();` → `value = null;` | Statement necessity |

See `test/features/estimations/mutations/add_cost_estimation_usecase.xml` for a worked example (23 rules covering all six categories).

### Canonical Test Pattern — Boundary Mutants

When the survived mutant is a boundary change (`>` → `>=`), add a boundary-equality test:

```dart
// Source
if (age >= 18) grantAccess();

// Tests that kill the boundary mutant
test('grants access at the boundary (age == 18)', () { /* … */ });
test('denies access just below the boundary (age == 17)', () { /* … */ });
```

The same shape applies to arithmetic mutants (assert exact result for non-zero and zero inputs) and branch mutants (one test per branch).

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep / Indicator | Severity |
|---|---|---|
| Logic-heavy file with no mutation run | `grep -rn "if.*&&\\|if.*\\|\\|" lib/features/**/domain/ \| wc -l` (3+ in one file) and no mutation report | Major |
| Mutation score below threshold (85% critical / 70% non-critical) | mutation-test-report or PR description | Critical (<60%) / Major (60% – threshold) |
| Surviving mutant in auth / payment / authorization | identify file + line in mutation report | Critical |

### Review Questions

1. Does this PR modify logic-heavy code? → if yes, expect mutation results.
2. What's the mutation score? → <60% Critical, 60% – threshold Major, ≥ threshold pass (threshold is 85% for critical paths, 70% otherwise).
3. Are surviving mutants in critical paths? → Critical.
4. Were new tests added to kill the surviving mutants? → expect tests for each.

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|---|---|---|
| Complex logic added, no mutation testing | Run mutation tests, report score | Major |
| Mutation score below threshold (85% critical / 70% non-critical) | Add tests for surviving mutants | Critical |
| Surviving mutant in auth / payment logic | Add test for that specific condition | Critical |
| No mutation testing in PR with calculations | Run mutation tests on the calculation logic | Major |

---

## Summary

**Dev workflow:** identify logic-heavy files → run mutation tests on them → kill surviving mutants → include score in PR description.

**Reviewer workflow:** spot logic changes → require mutation score → enforce thresholds (85% critical paths, 70% non-critical) → no surviving mutants in critical paths.

## References

- [Mutation Testing (Wikipedia)](https://en.wikipedia.org/wiki/Mutation_testing)
- [Dart `mutation_test` package](https://pub.dev/packages/mutation_test) — declared as `dev_dependency` in `pubspec.yaml`
- CI runner: `scripts/run_check.sh` (`run_mutation_tests`, line 202) and `docs/Testing/CI-Scripts.md`
- Review Script Lines: 484-496 in `scripts/review_pr.sh`

**Related:** if you also need to *run* the tool (commands, config XML, output interpretation), the `write-tests-mutation` skill is the operational runbook.

## Notes

**Mutation testing vs code coverage:** coverage asks "did this line run?"; mutation asks "do tests verify this line is correct?". 100% coverage with weak assertions still passes survived mutants.

**Cost:** mutation testing is slow — run on changed files only, in PR review (not every commit).
