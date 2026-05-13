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

## What is Mutation Testing?

**Concept:** Mutation testing modifies your code (introduces "mutants") and checks if your tests catch the bugs.

**Core Principle:** Code coverage tells you IF tests executed a line; mutation testing tells you if tests VERIFY the line is correct.

**Example:**
```dart
// Original code
if (amount > 0) {
  processPayment(amount);
}

// Mutant 1: Changed > to >=
if (amount >= 0) {  // 🧬 Mutant
  processPayment(amount);
}

// If your tests pass with this mutant, you're missing a boundary test!
```

## Logic Classification

**Critical Logic** (requires 80% mutation score):
- Authentication/authorization systems
- Payment processing
- Financial calculations
- Access control checks
- Data validation that affects security/correctness

**Non-Critical Logic** (60% mutation score acceptable):
- Display formatting
- Sorting/filtering for UI
- Non-essential calculations
- Secondary features

## Running Mutation Tests

**Step 1: Create mutation config file**

**File location:** `test/features/{feature}/mutations/{file}_mutations.xml`

**Basic structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
    <files>
        <file>lib/features/{feature}/domain/usecases/{usecase}.dart</file>
    </files>

    <exclude>
        <!-- Exclude logging statements -->
        <regex pattern="_logger\.(debug|info|warning|error)\s*\(" dotAll="false"/>
        <!-- Exclude try-catch structure -->
        <regex pattern="try\s*{" dotAll="false"/>
        <regex pattern="catch\s*\(" dotAll="false"/>
    </exclude>

    <rules>
        <!-- Define specific mutations to test -->
        <regex pattern="if \(amount > 0\)" dotAll="true" id="boundary.check">
            <mutation text="if (amount >= 0)"/>
        </regex>
    </rules>

    <commands>
        <command group="{usecase}" expected-return="0">
            flutter test test/features/{feature}/units/domain/usecases/{usecase}_test.dart
        </command>
    </commands>

    <threshold failure="80">
        <rating over="85" name="A"/>
        <rating over="75" name="B"/>
        <rating over="65" name="C"/>
        <rating over="0" name="F"/>
    </threshold>
</mutations>
```

**Step 2: Run mutation tests**

```bash
# Using mutant package
dart run mutant --config test/features/{feature}/mutations/{file}_mutations.xml

# Or target specific file directly
dart run mutant \
  --file lib/features/{feature}/domain/usecases/{usecase}.dart \
  --test-file test/features/{feature}/units/domain/usecases/{usecase}_test.dart
```

**Step 3: Analyze results**

```
Mutation Score: 85% (17/20 mutants killed)

Surviving Mutants:
- Line 42: Changed > to >= (SURVIVED)
- Line 58: Removed null check (SURVIVED)
- Line 71: Changed + to - (SURVIVED)
```

## Common Mutation Types

| Mutation Type | Example | What it Tests |
|---------------|---------|---------------|
| **Conditional Boundary** | `>` → `>=` | Boundary conditions |
| **Negation** | `if (x)` → `if (!x)` | Boolean logic |
| **Arithmetic** | `+` → `-`, `*` → `/` | Calculations |
| **Return Value** | `return x` → `return null` | Null handling |
| **Constant** | `0.1` → `0.0` | Magic numbers |
| **Statement Deletion** | Remove line | Statement necessity |

## Interpreting Results

**Mutant Killed ✅:**
```
✓ Mutant: Changed > to >= on line 42
  Test: should not process zero amount
  Status: KILLED
```
→ Good! Your test caught the bug.

**Mutant Survived ❌:**
```
✗ Mutant: Changed > to >= on line 42
  Test: (no test failed)
  Status: SURVIVED
```
→ Gap in tests! Add test for boundary condition.

**Equivalent Mutant ⚠️:**
```
~ Mutant: Changed && to &
  Note: Logically equivalent
  Status: EQUIVALENT
```
→ Can't be killed (doesn't change behavior). Mark as equivalent.

## Adding Tests to Kill Mutants

**Strategy 1: Test Boundary Conditions**

```dart
// Code with boundary
if (age >= 18) {
  grantAccess();
}

// Tests to kill boundary mutants
test('should grant access when age is exactly 18', () { });  // Boundary
test('should deny access when age is 17', () { });  // Just below
test('should grant access when age is 19', () { });  // Just above
```

**Strategy 2: Test All Branches**

```dart
// Code with multiple branches
if (status == 'active') {
  return ActiveState();
} else if (status == 'pending') {
  return PendingState();
} else {
  return InactiveState();
}

// Tests to kill branch mutants
test('should return ActiveState when status is active', () { });
test('should return PendingState when status is pending', () { });
test('should return InactiveState when status is neither', () { });
```

**Strategy 3: Test Calculations**

```dart
// Code with calculation
double calculateTax(double price) {
  return price * 0.08;
}

// Tests to kill arithmetic mutants
test('should calculate 8% tax correctly', () {
  expect(calculateTax(100.0), 8.0);  // Kills * → /, * → +, etc.
});
test('should return 0 for 0 price', () {
  expect(calculateTax(0.0), 0.0);  // Kills constant mutations
});
```

## File Organization

```
test/features/{feature}/mutations/
├── {usecase}_mutations.xml
├── {repository}_impl_mutations.xml
└── {datasource}_mutations.xml
```

**Mutation configs are manually created for logic-heavy files only.**

## Mutation Score Target

| Score | Quality | Action |
|-------|---------|--------|
| **80-100%** | Excellent ✅ | Good coverage |
| **60-79%** | Acceptable ⚠️ | For non-critical logic only |
| **<60%** | Insufficient ❌ | Add more tests |

**Note:** 100% is ideal but not always necessary. Some mutants are equivalent (don't change behavior).

### Handling Low Mutation Scores

**If score <60%:**
1. Review list of surviving mutants
2. Identify which mutants are in critical code paths
3. Add tests targeting those specific mutations (see "Adding Tests to Kill Mutants")
4. Re-run mutation tests to verify improvements
5. If score remains low, investigate whether code has unnecessary complexity

**If score 60-79%:**
- Acceptable for non-critical logic
- For critical logic (auth, payment), add more tests until ≥80%

### Error Handling

**If mutation tool fails:**
1. Check XML config file for syntax errors
2. Verify `dart run mutant` package is installed: `dart pub global activate mutant`
3. Ensure test file path in `<commands>` is correct
4. Check that target file exists and compiles
5. Run tests manually first to verify they pass: `flutter test {test_file_path}`

## Typical Targets

**✅ Run mutation tests for:**
- `lib/features/**/domain/usecases/*.dart` — Complex UseCases
- `lib/features/**/domain/services/*.dart` — Business services
- `lib/features/**/data/repositories/*_impl.dart` — If contains logic
- `lib/features/**/data/data_source/*.dart` — If contains transformation logic

**❌ Skip mutation tests for:**
- `lib/features/**/presentation/**` — UI code (use widget tests)
- `lib/features/**/data/models/**` — DTOs (simple mapping)
- Generated code

## Best Practices

1. **Run during PR review** — Not on every commit (mutation testing is slow)
2. **Target changed files only** — Don't run on entire codebase
3. **Document in PR** — Include mutation score in PR description
4. **Focus on critical paths** — Authentication, authorization, payment, validation
5. **80% minimum** — For critical logic; 60% acceptable for non-critical

## Key Principles

1. **Gated skill** — Only for logic-heavy changes (3+ conditional branches)
2. **Quality over quantity** — Code coverage ≠ test quality
3. **Test boundaries** — Edge cases (0, null, empty, max values)
4. **Test all branches** — Every conditional path
5. **80% mutation score** — Minimum for critical logic

## References

- **RULE_13:** `skills/rules/13-mutation-testing.md` — Mutation testing for logic-heavy changes
- **Examples:** `test/features/estimations/mutations/add_cost_estimation_usecase.xml`
- **Mutation Package:** [Dart Mutant](https://pub.dev/packages/mutant)
- **Concept:** [Mutation Testing Introduction](https://en.wikipedia.org/wiki/Mutation_testing)

