# State Derivation (MERGED)

> **⚠️ This rule has been merged into `UI / Business Separation`**
>
> **Location:** `skills/rules/05-ui-business-separation.md`
>
> **Section:** "Core Principle 2: No State Derivation"

## Name
State Derivation (Deprecated - use UI / Business Separation)

## Migration Note

`State Derivation` and `UI / Business Separation` have been merged because both enforce UI purity. The combined rule now covers:

1. **Business logic separation** - No validation, coordination, or decisions in UI
2. **State derivation** - No calculations, transformations, or derived values in UI

## Where to Find This Content Now

All content from `State Derivation` is now in:
- **File:** `skills/rules/05-ui-business-separation.md`
- **Section:** "Core Principle 2: No State Derivation"

Key topics covered:
- Widget must not calculate or transform state
- No cross-state coordination in build methods
- Derived values belong in BLoC selectors or UseCase
- Detection patterns for state derivation violations

## Quick Reference

### ❌ State Derivation (Forbidden in UI)

```dart
// ❌ Bad: Calculating in widget
Widget build(BuildContext context) {
  final total = estimations.fold(0.0, (sum, e) => sum + e.amount);  // ❌
  return Text('Total: \$${total}');
}
```

### ✅ State Already Derived (Correct)

```dart
// ✅ Good: BLoC calculates, UI renders
class EstimationState {
  final List<Estimation> estimations;
  final double totalAmount;  // ✅ Pre-calculated by BLoC
}

Widget build(BuildContext context) {
  return Text('Total: \$${state.totalAmount}');  // ✅ Just render
}
```

## For Skills Referencing State Derivation

If your skill references `State Derivation`, update to reference
`UI / Business Separation` instead:

```bash
# Old reference
cat skills/rules/12-state-derivation.md

# New reference
cat skills/rules/05-ui-business-separation.md
# Look for section: "Core Principle 2: No State Derivation"
```

## Detection Patterns

Search for these violations in UI code:
- `.fold(`, `.reduce(`, `.map(` in build methods
- `where()`, `firstWhere()` filtering state
- Calculations like `sum`, `average`, `percentage`
- Index manipulation like `indexOf()`, `sublist()`
- Cross-state coordination (combining multiple state properties)

---

**See:** `skills/rules/05-ui-business-separation.md` for the complete merged rule.
