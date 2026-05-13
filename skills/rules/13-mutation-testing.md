# RULE 13: Mutation Testing for Logic-Heavy Changes

## Rule ID
RULE_13

## Category
Testing - Quality Assurance

## Severity Levels
- **Critical:** Logic-heavy PR with <80% mutation score and surviving mutants in critical paths
- **Major:** Complex business logic added without mutation testing
- **Minor:** Mutation testing not run on logic-heavy components
- **Suggestion:** Consider mutation testing for branches with 3+ conditional paths

## Description

PRs that introduce or modify complex business logic, mathematical calculations, or data transformations must be validated with mutation testing. This ensures unit tests actually verify correctness, not just code coverage.

**Core Principle:** Mutation testing finds gaps in your test suite by introducing bugs (mutants) and checking if tests catch them.

## Applicability

**This is a GATED practice.** Only apply to:
- Files with complex business logic (3+ conditional branches)
- Mathematical calculations or algorithms
- Data transformation logic (pagination, filtering, sorting)
- Critical decision paths (authentication, authorization, payment)

**DO NOT apply to:**
- Simple CRUD operations
- UI/presentation code (use widget tests instead)
- Generated code

**Typical targets:**
- `lib/features/**/domain/usecases/*.dart`
- `lib/features/**/domain/services/*.dart`
- `lib/features/**/data/repositories/*_impl.dart`
- `lib/features/**/data/data_source/*.dart` (if contains logic)

---

## For Coding Agents (Prescriptive)

### Decision Gate: Should I Run Mutation Testing?

```
Does the class contain logic-heavy code?

├─ Complex conditionals (3+ branches)?
│  └─ YES → Run mutation testing
│
├─ Mathematical calculations?
│  └─ YES → Run mutation testing
│
├─ Data transformation logic?
│  └─ YES → Run mutation testing
│
├─ Critical decision paths?
│  └─ YES → Run mutation testing
│
└─ Simple CRUD or UI code?
   └─ NO → Skip mutation testing
```

### What is Mutation Testing?

**Concept:** Mutation testing modifies your code (introduces "mutants") and checks if your tests catch the bugs.

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

// Mutant 2: Changed > to <
if (amount < 0) {  // 🧬 Mutant
  processPayment(amount);
}

// Mutant 3: Removed condition
processPayment(amount);  // 🧬 Mutant

// If your tests pass with any of these mutants,
// it means you have a gap in your test coverage!
```

### When to Use

**✅ Run mutation testing for:**

- **Complex conditionals:**
  ```dart
  if (user.isAdmin && project.isActive || user.isOwner) {
    // Logic with multiple conditions
  }
  ```

- **Mathematical operations:**
  ```dart
  double calculateDiscount(double price, int loyaltyPoints) {
    final baseDiscount = price * 0.1;
    final bonusDiscount = loyaltyPoints > 1000 ? price * 0.05 : 0;
    return baseDiscount + bonusDiscount;
  }
  ```

- **Data transformations:**
  ```dart
  List<Estimation> paginateEstimations(List<Estimation> all, int page, int pageSize) {
    final start = page * pageSize;
    final end = min(start + pageSize, all.length);
    return all.sublist(start, end);
  }
  ```

**❌ Skip mutation testing for:**

- Simple getters/setters
- UI widgets
- Data models (freezed classes)
- Simple CRUD without logic

### How to Run Mutation Testing

**Step 1: Install mutant (mutation testing tool)**

```yaml
# pubspec.yaml
dev_dependencies:
  mutant: ^latest_version
  # See: https://pub.dev/packages/mutant
```

**Step 2: Run mutation tests on specific file**

```bash
# Target specific logic-heavy file
dart run mutant \
  --file lib/features/estimation/domain/usecases/calculate_total_usecase.dart \
  --test-file test/features/estimation/domain/usecases/calculate_total_usecase_test.dart
```

**Step 3: Analyze results**

```
Mutation Score: 85% (17/20 mutants killed)

Surviving Mutants:
- Line 42: Changed > to >= (SURVIVED)
- Line 58: Removed null check (SURVIVED)
- Line 71: Changed + to - (SURVIVED)
```

**Step 4: Add tests for surviving mutants**

```dart
// Surviving mutant: Changed > to >=
// This means we're missing a boundary test!

// Add test
test('should not process payment when amount is exactly zero', () async {
  final result = await useCase.execute(amount: 0.0);

  expect(result.isLeft(), true);  // Should fail, not process
  // ✅ Now mutant is killed
});
```

### Target: 80% Mutation Score

**Acceptable mutation score: ≥80%**

- 80-100%: Excellent coverage ✅
- 60-79%: Acceptable for non-critical logic ⚠️
- <60%: Insufficient, add more tests ❌

**Note:** 100% is ideal but not always necessary. Some mutants are equivalent (don't change behavior).

### Common Mutation Types

| Mutation Type | Example | What it Tests |
|---------------|---------|---------------|
| **Conditional Boundary** | `>` → `>=` | Boundary conditions |
| **Negation** | `if (x)` → `if (!x)` | Boolean logic |
| **Arithmetic** | `+` → `-`, `*` → `/` | Calculations |
| **Return Value** | `return x` → `return null` | Null handling |
| **Constant** | `0.1` → `0.0` | Magic numbers |
| **Statement Deletion** | Remove line | Statement necessity |

### Writing Tests to Kill Mutants

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

### Interpreting Results

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
  Note: Logically equivalent (no short-circuit difference)
  Status: EQUIVALENT
```
→ Can't be killed (doesn't change behavior). Mark as equivalent.

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: Logic-Heavy Files Without Mutation Testing**

Identify files with complex logic:

```bash
# Find files with multiple conditionals
grep -rn "if.*&&\|if.*||" lib/features/**/domain/ | wc -l

# Find files with calculations
grep -rn "[+\-*/]" lib/features/**/domain/usecases/ lib/features/**/data/repositories/
```

**If file has 3+ conditional branches** → Should have mutation test results

**Pattern 2: Low Mutation Score in PR**

Check if mutation score is mentioned:
- Look for mutation test output in PR description or comments
- Check for `mutation_score:` annotation

**If mutation score <80%** → Major violation

**Pattern 3: Surviving Mutants in Critical Paths**

Critical paths:
- Authentication/authorization logic
- Payment/financial calculations
- Data validation logic
- Access control checks

**If critical path has surviving mutants** → Critical violation

### Review Questions

1. **Does this PR modify logic-heavy code?**
   - If YES → Check for mutation test results

2. **What is the mutation score?**
   - <60%: Critical
   - 60-79%: Major
   - ≥80%: Good ✅

3. **Are there surviving mutants?**
   - Check which mutants survived
   - Are they in critical code paths?

4. **Were new tests added to kill mutants?**
   - Look for test additions addressing gaps

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| Complex logic added, no mutation testing | Run mutation tests, report score | Major |
| Mutation score <80% | Add tests for surviving mutants | Critical |
| Surviving mutant in auth logic | Add test for that specific condition | Critical |
| No mutation testing in PR with calculations | Run mutation tests on calculation logic | Major |

---

## Summary: How to Apply

**For Developers:**

1. **Before PR:** Identify logic-heavy files you changed
2. **Run mutation tests:** Target those specific files
3. **Analyze results:** Note mutation score and surviving mutants
4. **Add tests:** Write tests to kill surviving mutants
5. **Document in PR:** Include mutation score in PR description

**For Reviewers:**

1. **Identify logic changes:** Look for complex conditionals, calculations
2. **Request mutation testing:** If logic-heavy and not tested
3. **Check score:** Ensure ≥80% mutation score
4. **Review surviving mutants:** Ensure none in critical paths

## References

- [Mutation Testing Introduction](https://en.wikipedia.org/wiki/Mutation_testing)
- [Stryker Mutator](https://stryker-mutator.io/) - Popular mutation testing framework
- [Dart Mutant Package](https://pub.dev/packages/mutant)
- Review Script Lines: 484-496 in `scripts/review_pr.sh`

## Notes

**Mutation Testing vs Code Coverage:**

- **Code Coverage:** Did tests execute this line? (quantity)
- **Mutation Testing:** Do tests verify this line is correct? (quality)

You can have 100% code coverage but still have bugs that tests don't catch. Mutation testing finds those gaps.

**Best Practice:** Run mutation testing during PR review for logic-heavy changes, not on every commit (it's slow).

**Time Consideration:** Mutation testing is computationally expensive. Run it only on changed files, not entire codebase.
