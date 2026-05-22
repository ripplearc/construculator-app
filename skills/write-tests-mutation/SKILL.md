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

Location: `test/features/{feature}/mutations/{file}_mutations.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
    <files>
        <file>lib/features/{feature}/domain/usecases/{usecase}.dart</file>
    </files>

    <exclude>
        <regex pattern="_logger\.(debug|info|warning|error)\s*\(" dotAll="false"/>
        <regex pattern="try\s*{" dotAll="false"/>
        <regex pattern="catch\s*\(" dotAll="false"/>
    </exclude>

    <rules>
        <!-- Define mutations specific to the logic under test -->
    </rules>

    <commands>
        <!-- timeout in seconds: set to ~2x your normal test run time to catch infinite loops from mutations -->
        <command group="{usecase}" expected-return="0" timeout="60">
            flutter test test/features/{feature}/units/domain/usecases/{usecase}_test.dart
        </command>
    </commands>

    <threshold failure="85">
        <rating over="90" name="A"/>
        <rating over="85" name="B"/>
        <rating over="70" name="C"/>
        <rating over="0" name="F"/>
    </threshold>
</mutations>
```

**Step 2: Run**

```bash
dart run mutant --config test/features/{feature}/mutations/{file}_mutations.xml
```

**Step 3: Check the score**

The report is written to `mutation-test-report/mutation-test-report.html`. Read it directly — it is always small (~8KB) and contains the overall score, detected/total counts, and quality rating.

**If score ≥ 85% → done.**

**If score < 85% → extract undetected mutations:**

```bash
# List every survived mutation ID across all detail files
find mutation-test-report/lib -name "*.dart.html" -exec \
  grep -l "Undetected" {} \; | while read f; do
    echo "=== $f ===";
    grep -A8 "Undetected mutations" "$f" | grep -o 'Id: [^<]*';
  done
```

⚠️ Do NOT read per-file detail HTML files in full — they can be 75KB+. Use the grep above instead.

For each survived mutation ID, add a test that directly asserts the behavior the mutation changes (boundary value, branch path, return value, etc.). Then re-run until score ≥ 85%.

## File Organization

```
test/features/{feature}/mutations/
├── {usecase}_mutations.xml
├── {repository}_impl_mutations.xml
└── {datasource}_mutations.xml
```

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
