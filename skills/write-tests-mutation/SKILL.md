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

- **Critical (85% score):** auth/authorization, payments, financial calculations, access control, security-relevant validation.
- **Non-critical (70% score):** display formatting, UI-side sorting/filtering, secondary features.

## Running Mutation Tests

**Tool:** Dart package `mutation_test` (declared as `dev_dependency` in `pubspec.yaml`, currently `mutation_test: 1.7.0`). Not `mutant`.

**Step 1: Create mutation config**

Copy `test/features/estimations/mutations/add_cost_estimation_usecase.xml` as a template. The XML schema:
- `<files>` — single source file under test.
- `<exclude>` — regex patterns for noise mutations (logger calls, try/catch structure).
- `<rules>` — hand-authored `<regex pattern="..." id="..."><mutation text="..."/></regex>` entries. With `--no-builtin`, ONLY these custom rules run.
- `<commands>` — `<command group="..." expected-return="0">flutter test <test-file></command>`. No `timeout` attribute is used.
- `<threshold failure="N">` — score threshold inside the XML. Convention: `85` for critical paths (auth, payments, security), `70` for non-critical.

Location: `test/features/{feature}/mutations/{file}.xml` or `test/libraries/{lib}/mutations/{file}.xml`.

**Step 2: Run**

Direct invocation:

```bash
dart run mutation_test <config1.xml> [<config2.xml> ...] --no-builtin
```

CI invocation (preferred for PR work): mutation tests run automatically when XML config files change. Trigger via:
- Local: `./scripts/run_check.sh --mutations` (see `run_mutation_tests()` in `scripts/run_check.sh:202`).
- Codemagic: comment `#runcheck` on the PR — the CI workflow runs the mutation check on changed XML configs.

**Step 3: Check the score**

Read `mutation-test-report/mutation-test-report.html` — it is small (~8KB) and contains the overall score, detected/total counts, and quality rating.

If score ≥ threshold (`<threshold failure>` from the XML) → done. If score is below, grep each detail file under `mutation-test-report/lib/` for `Undetected` to identify survived mutation IDs. Add a test for each that asserts the specific behavior the mutation changes, then re-run.

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
- `lib/features/**/data/repositories/*_impl.dart` — if it contains logic
- `lib/features/**/data/data_source/*.dart` — if it contains transformation logic
- `lib/libraries/**/...` — many existing configs live under `test/libraries/**/mutations/`

**❌ Skip:**
- `lib/features/**/data/models/**`
- Generated code

**Note on presentation:** the repo *does* have mutation configs for presentation BLoCs and pages (e.g. `test/features/auth/mutations/login_with_email_bloc.xml`, `login_with_email_page_mutations.xml`). Apply the gate per-file based on logic density, not blanket layer exclusion.

## Best Practices

1. Run during PR review, not on every commit (slow).
2. Target changed files only; focus on critical paths.
3. Read `mutation-test-report/mutation-test-report.html` for the score; grep detail HTML under `mutation-test-report/lib/` for survived mutation IDs — never read detail files in full (75KB+).

## References

- **RULE_13:** `skills/rules/13-mutation-testing.md`
- **Example config:** `test/features/estimations/mutations/add_cost_estimation_usecase.xml`
- **CI runner:** `scripts/run_check.sh` (`run_mutation_tests` function, line 202)
- **CI docs:** `docs/Testing/CI-Scripts.md` — "Mutation testing behavior" section
- **Package:** `mutation_test` on pub.dev — already declared as `dev_dependency` in `pubspec.yaml` (currently 1.7.0)
