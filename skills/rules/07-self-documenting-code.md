# RULE 7: Self-Documenting & Clean Code

## Rule ID
RULE_7

## Category
Code Quality & Maintainability

## Severity Levels
- **Critical:** AI-generated artifacts or placeholder comments in production code
- **Major:** Step-by-step narrative comments explaining what code does
- **Minor:** Obscure naming requiring explanatory comments
- **Suggestion:** Refactor complex logic into descriptive helper methods

## Description

Code must be expressive and self-explanatory. Use documentation for contracts and public APIs, but avoid implementation comments that explain logic. If you need a comment to explain *what* code does, the code should be refactored to be clearer.

**Two Types of Comments:**
1. **Code Documentation** ✅ - Explains *purpose* and *usage* of APIs
2. **Implementation Comments** ❌ - Explains *what* each line does

## Applicability

Applies to all production code in `lib/` directory.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Write code that reads like a story.** Variable names, function names, and structure should make the code's intent obvious without requiring comments.

### What TO Write (Code Documentation)

✅ **Document Public APIs:**

```dart
/// Fetches initial estimations for a project and resets pagination state.
///
/// This method performs a network request and clears any existing
/// pagination cursors. Use [fetchNextEstimations] for subsequent pages.
///
/// Returns a [Future] that completes with [Either]:
/// - [Right]: List of estimations if successful
/// - [Left]: [Failure] if network error or parsing fails
///
/// Example:
/// ```dart
/// final result = await repository.fetchInitialEstimations('project-123');
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (estimations) => print('Loaded ${estimations.length} items'),
/// );
/// ```
Future<Either<Failure, List<Estimation>>> fetchInitialEstimations(String projectId);
```

✅ **Document Class Purpose:**

```dart
/// Repository for managing cost estimation data.
///
/// Provides access to estimation CRUD operations and real-time updates
/// via streams. Abstracts the underlying data source (Supabase) from
/// the domain layer.
///
/// **Lifecycle:** Call [dispose] when no longer needed to clean up stream
/// controllers and prevent memory leaks.
abstract class EstimationRepository {
  // ...
}
```

✅ **Document Non-Obvious State:**

```dart
class EstimationBloc {
  /// Tracks the last scroll position to implement infinite scroll pagination.
  ///
  /// Reset to 0.0 when user navigates away or refreshes the list.
  double _lastScrollPosition = 0.0;
}
```

### What NOT TO Write (Implementation Comments)

❌ **AI Residuals:**

```dart
// Bad: AI-generated placeholders
void login(String email, String password) {
  // <-- ADD THIS
  validateEmail(email);  // ❌

  // TODO: implementation here  // ❌

  // Fix: removed hardcoded value  // ❌
}

// Good: Just the code
void login(String email, String password) {
  validateEmail(email);  // ✅ No comment needed
  authenticateUser(email, password);
}
```

❌ **Step-by-Step Narratives:**

```dart
// Bad: Explaining what each line does
void calculateTotal(List<Item> items) {
  // Initialize total to zero  // ❌
  double total = 0.0;

  // Loop through all items  // ❌
  for (final item in items) {
    // Add item price to total  // ❌
    total += item.price;

    // Apply tax if item is taxable  // ❌
    if (item.isTaxable) {
      total += item.price * 0.08;  // ❌ What is 0.08?
    }
  }

  return total;
}

// Good: Self-documenting with constants and extraction
void calculateTotal(List<Item> items) {
  return items.fold(0.0, (total, item) => total + _itemTotal(item));
}

double _itemTotal(Item item) {
  final basePrice = item.price;
  final tax = item.isTaxable ? basePrice * _taxRate : 0.0;
  return basePrice + tax;
}

static const double _taxRate = 0.08;  // ✅ Named constant
```

❌ **Obscure Naming with Comments:**

```dart
// Bad: Generic names requiring comments
void processData(Map<String, dynamic> data) {
  // Extract user information  // ❌
  final val = data['user'];

  // Convert to user model  // ❌
  final info = UserMapper.fromJson(val);

  // Save to database  // ❌
  repo.save(info);
}

// Good: Descriptive names, no comments needed
void saveUserFromApiResponse(Map<String, dynamic> apiResponse) {
  final userJson = apiResponse['user'];
  final userModel = UserMapper.fromJson(userJson);
  repository.saveUser(userModel);
}
```

### Refactor vs. Comment

**When you feel the urge to add a comment, refactor instead:**

#### Example 1: Extract Complex Condition

```dart
// Bad: Comment explains condition
if (user != null && user.isActive && user.subscriptionExpiry.isAfter(DateTime.now())) {  // Check if user has valid subscription  ❌
  grantAccess();
}

// Good: Extract to descriptive method
if (_hasValidSubscription(user)) {  // ✅ Self-explanatory
  grantAccess();
}

bool _hasValidSubscription(User? user) {
  return user != null &&
         user.isActive &&
         user.subscriptionExpiry.isAfter(DateTime.now());
}
```

#### Example 2: Extract Magic Numbers

```dart
// Bad: Comment explains magic number
await Future.delayed(Duration(milliseconds: 500));  // Wait for animation to complete  ❌

// Good: Named constant
static const _animationDuration = Duration(milliseconds: 500);
await Future.delayed(_animationDuration);  // ✅
```

#### Example 3: Extract Complex Calculation

```dart
// Bad: Comment explains calculation
final discount = price * 0.1 + (loyaltyPoints > 1000 ? price * 0.05 : 0);  // Calculate total discount  ❌

// Good: Extract method with clear name
final discount = _calculateTotalDiscount(price, loyaltyPoints);  // ✅

double _calculateTotalDiscount(double price, int loyaltyPoints) {
  final baseDiscount = price * 0.1;
  final loyaltyDiscount = loyaltyPoints > 1000 ? price * 0.05 : 0;
  return baseDiscount + loyaltyDiscount;
}
```

### Naming Guidelines

**Use names that eliminate the need for comments:**

| ❌ Requires Comment | ✅ Self-Documenting |
|---------------------|---------------------|
| `int c`  // count | `int estimationCount` |
| `bool f`  // flag for processing | `bool isProcessingPayment` |
| `var data`  // user information | `User user` or `UserData userData` |
| `void process()`  // saves to DB | `void saveToDatabase()` |
| `double calc()`  // calculates tax | `double calculateSalesTax()` |

**Naming Patterns:**

- **Booleans:** `is...`, `has...`, `should...`, `can...`
  - `isLoading`, `hasValidCredentials`, `shouldShowError`, `canEdit`

- **Collections:** Plural nouns
  - `estimations`, `users`, `errors` (not `estimationList`, `userArray`)

- **Methods:** Verb phrases
  - `fetchEstimations()`, `calculateTotal()`, `validateEmail()`

- **Classes:** Nouns describing responsibility
  - `EstimationCalculator`, `EmailValidator`, `UserRepository`

### When Comments ARE Appropriate

✅ **Non-Obvious Business Rules:**

```dart
// ✅ Good: Explains WHY, not WHAT
// Tax rate changes to 9% for commercial properties per 2024 tax law
static const _commercialTaxRate = 0.09;
```

✅ **Workarounds or Known Issues:**

```dart
// ✅ Good: Documents technical constraint
// Supabase doesn't support nested transactions, so we commit each stage separately
// See: https://github.com/supabase/supabase/issues/1234
await _commitStageOne();
await _commitStageTwo();
```

✅ **Complex Algorithms (when extraction isn't enough):**

```dart
/// Implements binary search with early termination optimization.
///
/// Time complexity: O(log n)
/// Space complexity: O(1)
///
/// Returns index of item, or -1 if not found.
int binarySearch(List<int> sorted, int target) {
  // Implementation follows...
}
```

### Common Anti-Patterns

❌ **Commented-Out Code:**

```dart
// Bad: Dead code left in
void login(String email, String password) {
  // Old implementation
  // await authenticateWithFirebase(email, password);

  // New implementation
  await authenticateWithSupabase(email, password);
}

// Good: Remove dead code, use git for history
void login(String email, String password) {
  await authenticateWithSupabase(email, password);
}
```

❌ **Changelog Comments:**

```dart
// Bad: Inline changelog
void calculateDiscount(double price) {
  // Updated 2024-01-15: Changed from 10% to 15%
  // Updated 2024-02-01: Added loyalty bonus
  return price * 0.15 + _loyaltyBonus();
}

// Good: Use git commit messages for history
void calculateDiscount(double price) {
  return price * _standardDiscountRate + _loyaltyBonus();
}

static const double _standardDiscountRate = 0.15;
```

❌ **Redundant Comments:**

```dart
// Bad: Comment repeats what code says
// Get user by ID  ❌
final user = await getUserById(id);

// Increment counter  ❌
counter++;

// Return true  ❌
return true;
```

---

## For Review Agents (Detective)

### Detection Patterns

**Pattern 1: AI Residuals**

```bash
# Search for common AI artifacts
grep -rn "// <--" lib/
grep -rn "// ADD THIS" lib/
grep -rn "// implementation here" lib/
grep -rn "// TODO: implement" lib/
grep -rn "// Fix:" lib/
```

**Regex:** `//\s*(<--|ADD THIS|implementation here|TODO: implement|Fix:)`

**Severity:** Critical

**Pattern 2: Step-by-Step Narratives**

Look for methods with multiple consecutive single-line comments:

**Indicator:** 3+ consecutive lines with `//` comments inside a method

**Severity:** Major

**Pattern 3: Obscure Naming**

Variables with generic names (`data`, `info`, `val`, `tmp`, `x`, `y`) followed by comments:

**Regex:** `(var|final|const)\s+(data|info|val|tmp|temp|x|y|i|j|k)\s*=.*//`

**Severity:** Minor

**Pattern 4: Commented-Out Code**

```bash
# Find commented-out code blocks
grep -rn "^[[:space:]]*//.*await\|^[[:space:]]*//.*return\|^[[:space:]]*//.*if\|^[[:space:]]*//.*for" lib/
```

**Severity:** Major

**Pattern 5: Magic Numbers Without Constants**

Numeric literals (except 0, 1, -1) without named constants:

**Regex:** `(?<![a-zA-Z_])[2-9]\d*(?:\.\d+)?(?![a-zA-Z_0-9])` (excluding 0, 1, common loop indices)

**Context needed:** Check if number appears multiple times or has semantic meaning

**Severity:** Minor

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|-------------|--------|----------|
| `// <-- ADD THIS` | Delete AI placeholder | Critical |
| `// Loop through items` | Remove redundant comment | Major |
| `var data // user info` | Rename to `userData` or `userInfo` | Minor |
| Commented-out code block | Delete (use git for history) | Major |
| `0.08` without constant name | Extract to `static const _taxRate = 0.08;` | Minor |
| 5+ single-line comments in method | Extract complex logic to helper methods | Major |

### Review Questions

1. **Can this code be understood without the comments?**
   - If NO → Refactor, don't just add comments

2. **Does this comment explain WHY, or just WHAT?**
   - WHAT → Remove or refactor
   - WHY → Keep if non-obvious

3. **Is this comment up-to-date with the code?**
   - If NO → Critical issue (misleading documentation)

4. **Would a better variable/method name eliminate this comment?**
   - If YES → Rename, remove comment

---

## Summary: Suggested Fixes

1. **Remove AI artifacts:** Delete all `<-- ADD THIS`, `TODO: implement`, `Fix:` comments
2. **Refactor narrative comments:** Extract complex logic into descriptive methods
3. **Rename obscure variables:** Use meaningful names that don't need comments
4. **Delete commented-out code:** Use git for code history, not inline comments
5. **Extract magic numbers:** Create named constants for semantic values
6. **Keep contracts clear:** Document public APIs, class purposes, and non-obvious business rules

## References

- Clean Code by Robert C. Martin - Chapter 4: Comments
- [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation)
- Review Script Lines: 339-355 in `scripts/review_pr.sh`

## Notes

**The Prime Directive:** Code should read like well-written prose. Comments are a necessary evil when code cannot express intent alone—minimize them by writing better code.

**Good Documentation ≠ Good Comments:**
- Documentation explains contracts and usage (external view)
- Comments explain implementation (internal view)
- Prioritize the former, avoid the latter
