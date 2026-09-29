# RULE 5: UI Logic Separation & Clean Presentation

## Name
UI / Business Separation

## Category
Architecture & Presentation Layer

## Severity Levels
- Critical: Business logic, validation, or navigation decisions are handled directly in widgets
- Major: State derivation, calculations, or cross-state coordination in UI layer
- Minor: Logic that belongs in a BLoC or use case is embedded in the build method
- Suggestion: Move business behavior or derived state out of presentation code

## Description

UI components should be "Passive Viewers." They may decide *how* to present data (layout, styling), but must not derive *new meaning* from it or make business decisions.

**Two Core Principles:**
1. **No Business Logic:** UI emits intents (events) and consumes states. All validation, coordination, and decisions belong in BLoCs or UseCases.
2. **No State Derivation:** If a value requires business rules, cross-state coordination, or non-trivial computation, it belongs in the BLoC, not the Widget.

## Applicability

This rule applies to all presentation layer code in `lib/features/**/presentation/` and `lib/app/`.

---

## For Coding Agents (Prescriptive)

### What Widgets SHOULD Do

| Allowed | Example |
|---------|---------|
| **Render State** | Display BLoC-provided values directly: `Text(state.total)` |
| **Emit Events** | Dispatch without validation: `context.read<Bloc>().add(Event())` |
| **Layout Decisions** | Choose how to present: `items.isEmpty ? EmptyView() : ListView()` |
| **Styling** | Responsive padding, colors based on `MediaQuery` |

### What Widgets MUST NOT Do

| Forbidden | ❌ Bad Example | ✅ Fix |
|-----------|---------------|--------|
| **Business Validation** | `if (id != null) { bloc.add(Event()) }` | Always emit, BLoC validates |
| **Derive State** | `total = items.fold(0, (s,e) => s + e.amount)` | BLoC provides `state.total` |
| **Cross-State Coordination** | `canEdit = authState.isAdmin && dataState.editable` | Create coordinating BLoC |
| **Index Manipulation** | `itemCount: items.length + 1` with special case logic | BLoC provides composed `displayItems` |
| **Calculations** | `displayCount = items.length + (loading ? 1 : 0)` | BLoC provides `state.displayCount` |

### Preferred Patterns

**✅ Composed UI Models:** BLoC provides ready-to-render state with formatted strings, display lists that include headers/separators, and pre-calculated flags.

**✅ Structural Separation:** Use native layout (Slivers, Column) instead of dynamic index manipulation.

**✅ View Helpers (layout only):** Extract responsive layout decisions into getters (e.g., `get _shouldShowCompactLayout`), but never business calculations.

---

## For Review Agents (Detective)

### Detection Patterns

**Check for these violations in `lib/features/**/presentation/` and `lib/app/`:**

| Violation | Example | Severity | Fix |
|-----------|---------|----------|-----|
| **Guard checks before events** | `if (id != null) { bloc.add(...) }` | Critical | Always emit, BLoC validates |
| **Data transformation** | `items.map(...).toList()`, `.fold()`, `.where()` in build | Major | BLoC provides pre-shaped data |
| **Manual state coordination** | Multiple `context.read<Bloc>().state` combined | Major | Create coordinating BLoC |
| **Navigation decisions** | `if (state.isSuccess) { Navigator.push(...) }` | Critical | BLoC emits navigation events |
| **State duplication** | Copying BLoC state to local variables | Major | Consume state directly |
| **Derived calculations** | `itemCount: data.length + 1`, `.fold()` for totals | Major | BLoC emits calculated values |
| **Index manipulation** | `data[index - 1]`, `index == 0 ? header : data[index]` | Major | BLoC provides composed list |
| **Cross-state coordination** | `canEdit = authState.isAdmin && dataState.editable` | Major | Single coordinating BLoC |
| **Complex conditionals** | Nested ternaries for widget selection | Minor | BLoC emits distinct state types |

## Summary: Suggested Fixes

Move all business logic, validation, coordination, and state derivation into the BLoC, use case, or service layer. Keep widgets as passive viewers that only decide HOW to present data, not WHAT data to present.

## References

- [UI / Business Separation Gist: UI & Business Logic Separation](https://gist.github.com/ripplearcgit/f190fecc8f7124e511cb01283f9fbc31)
- [Architecture Layers Reference](../references/architecture-layers.md)
- Related: Naming & Abstraction (Naming Conventions) - ensures classes in right layer
