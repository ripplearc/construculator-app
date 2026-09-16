# RULE 7: Self-Documenting & Clean Code

## Name
Self-Documenting Code

## Category
Code Quality & Maintainability

## Severity Levels
- **Critical:** AI-generated artifacts or placeholder comments in production code
- **Major:** Step-by-step narrative comments explaining what code does
- **Minor:** Obscure naming requiring explanatory comments
- **Suggestion:** Refactor complex logic into descriptive helper methods

## Description

Code must be expressive and self-explanatory. Use documentation for contracts and public APIs; avoid implementation comments that explain logic. If you need a comment to explain *what* code does, refactor the code to be clearer.

**Two Types of Comments:**
1. **Code Documentation** ✅ — explains *purpose* and *usage* of public APIs (dartdoc on classes, methods, fields).
2. **Implementation Comments** ❌ — explains *what* each line does.

## Applicability

All production code in `lib/`.

---

## For Coding Agents (Prescriptive)

### Core Principle

**Write code that reads like a story.** Names and structure carry intent; comments are reserved for what code cannot say.

### What TO Write — Documentation

- **Public APIs:** dartdoc with purpose, contract, return shape (`Either<Failure, T>`), and an example. Document inputs that are not obvious from the type.
- **Class purpose:** one paragraph at the top of every public class — what it does, what it abstracts, lifecycle notes (e.g. dispose).
- **Non-obvious state:** brief dartdoc on private fields whose meaning isn't obvious from the name.

### What NOT to Write — Implementation Comments

- AI residuals (`// <-- ADD THIS`, `// TODO: implement`, `// Fix:`).
- Step-by-step narration (`// Initialize total to zero`, `// Loop through items`).
- Comments that restate the code (`// Increment counter` above `counter++`).
- Obscure names patched with comments (`var val // user info`) — rename instead.
- Commented-out code — delete it; git keeps history.
- Inline changelogs (`// Updated 2024-01-15: …`) — commit messages own history.

**Canonical bad/good pair (AI residuals):**

```dart
// ❌ Bad
void login(String email, String password) {
  // <-- ADD THIS
  validateEmail(email);
  // TODO: implementation here
}

// ✅ Good
void login(String email, String password) {
  validateEmail(email);
  authenticateUser(email, password);
}
```

### Refactor Instead of Commenting

When you reach for a comment, refactor instead:

- **Complex condition →** extract to a predicate method (`_hasValidSubscription(user)`).
- **Magic number →** extract to a named `static const` (`_animationDuration`, `_taxRate`).
- **Long calculation →** extract to a private helper with a descriptive verb name.

### Naming Guidelines

| ❌ Requires Comment | ✅ Self-Documenting |
|---|---|
| `int c` // count | `int estimationCount` |
| `bool f` // is processing | `bool isProcessingPayment` |
| `var data` // user info | `User user` / `UserData userData` |
| `void process()` // saves to DB | `void saveToDatabase()` |
| `double calc()` // tax | `double calculateSalesTax()` |

**Patterns:**
- Booleans: `is…` / `has…` / `should…` / `can…`
- Collections: plural nouns (`estimations`, not `estimationList`)
- Methods: verb phrases (`fetchEstimations()`, `calculateTotal()`)
- Classes: noun describing responsibility (`EstimationCalculator`, `UserRepository`)

### When Comments ARE Appropriate

Comments earn their place when they explain **why**, not **what**:

- **Non-obvious business rules:** `// Tax rate changes to 9% for commercial properties per 2024 tax law`
- **Workarounds:** `// Supabase doesn't support nested transactions; commit stages separately. https://github.com/supabase/supabase/issues/1234`
- **Algorithm intent** that survives extraction: complexity notes, contract on non-trivial private helpers.

---

## For Review Agents (Detective)

### Detection Patterns

| Pattern | Grep / Regex | Severity |
|---|---|---|
| AI residuals | `grep -rn "// <--\\|// ADD THIS\\|// implementation here\\|// TODO: implement\\|// Fix:" lib/` | Critical |
| Step-by-step narration | 3+ consecutive `//` lines inside a method body | Major |
| Obscure name + comment | `(var\\|final\\|const)\\s+(data\\|info\\|val\\|tmp\\|temp\\|x\\|y)\\s*=.*//` | Minor |
| Commented-out code | `grep -rn "^[[:space:]]*//.*\\(await\\|return\\|if\\|for\\)" lib/` | Major |
| Magic numbers | numeric literal ≥ 2 with no named constant context, used > once | Minor |
| Inline changelog | `grep -rn "// Updated 20[0-9][0-9]-" lib/` | Minor |

### Common Violations

| ❌ Violation | ✅ Fix | Severity |
|---|---|---|
| `// <-- ADD THIS` / `// TODO: implement` | Delete the placeholder | Critical |
| `// Loop through items` above a `for` | Delete the comment | Major |
| `var data // user info` | Rename to `userData` | Minor |
| Commented-out code block | Delete; use git for history | Major |
| `0.08` repeated without a constant | Extract to `static const _taxRate = 0.08;` | Minor |
| 5+ single-line comments in one method | Extract complex logic into helpers | Major |
| Inline changelog comment | Delete; commit messages own history | Minor |

### Review Questions

1. Can this code be understood without the comments? → if no, refactor (don't just comment more).
2. Does the comment explain WHY or WHAT? → WHAT → remove; WHY → keep if non-obvious.
3. Is the comment up to date with the code? → if no, it's misleading; remove or fix.
4. Would a better name eliminate the comment? → rename, remove comment.

---

## Summary: Suggested Fixes

1. Delete AI artifacts (`<-- ADD THIS`, `TODO: implement`, `Fix:`).
2. Refactor narrative comments — extract logic into named helpers.
3. Rename obscure variables — eliminate the comment by renaming.
4. Delete commented-out code; use git for history.
5. Extract magic numbers into named `static const`s.
6. Keep dartdoc on contracts: public APIs, class purpose, non-obvious business rules.

## References

- *Clean Code* by Robert C. Martin — Chapter 4: Comments
- [Effective Dart: Documentation](https://dart.dev/guides/language/effective-dart/documentation)
- Review Script Lines: 339-355 in `scripts/review_pr.sh`

## Notes

**The prime directive:** code reads like prose; comments are a necessary evil when code cannot express intent alone. Minimize them by writing better code.

**Documentation ≠ Comments:**
- Documentation explains contracts and usage (external view) — prioritize.
- Comments explain implementation (internal view) — avoid.
