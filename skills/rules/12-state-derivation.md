# RULE 12: No State Derivation in UI (MERGED)

> **⚠️ This rule has been merged into RULE_5: UI & Business Logic Separation**
>
> **Location:** `skills/rules/05-ui-business-separation.md`
>
> **Section:** "State Derivation (original RULE_12)"

## Rule ID
RULE_12 (Deprecated - use RULE_5)

## Migration Note

RULE_12 (No State Derivation in UI) and RULE_5 (UI & Business Logic Separation) have been merged because both enforce UI purity. The combined rule now covers:

1. **Business logic separation** (original RULE_5) - No validation, coordination, or decisions in UI
2. **State derivation** (original RULE_12) - No calculations, transformations, or derived values in UI

## Where to Find This Content Now

All content from RULE_12 is now in:
- **File:** `skills/rules/05-ui-business-separation.md`
- **Section:** Lines 130+ under "Core Principle 2: No State Derivation (original RULE_12)"

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

## For Skills Referencing RULE_12

If your skill references `RULE_12`, update to reference `RULE_5` instead:

```bash
# Old reference
cat skills/rules/12-state-derivation.md

# New reference
cat skills/rules/05-ui-business-separation.md
# Look for section: "Core Principle 2: No State Derivation (original RULE_12)"
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
