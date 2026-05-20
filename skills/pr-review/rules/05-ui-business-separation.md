# RULE 5: UI & Business Logic Separation

## Rule ID
RULE_5

## Category
Architecture

## Severity Levels
- Critical: Business logic, validation, or navigation decisions are handled directly in widgets.
- Major: Widgets duplicate state or coordinate business flows manually.
- Minor: Logic that belongs in a BLoC or use case is embedded in the build method.
- Suggestion: Move business behavior out of presentation code.

## Description

UI should render state and emit intents. It should not own domain decisions.

## Applicability

This rule applies to UI code that mixes rendering with validation, transformation, or coordination logic.

## Detection Patterns

- Guard checks in widgets before dispatching events.
- Data transformation in build methods.
- Manual coordination between separate state sources.
- Navigation based on business conditions inside the UI layer.

## Implementation Guide

**For Agent Execution:**

Search for violations in presentation code using these patterns:

### Pattern 1: Guard Checks Before Events

**Indicator:** Widget checks business rules before emitting an event

**Examples to catch:**
- `if (userId != null) { context.read<AuthBloc>().add(...) }`
- `if (amount > 0) { emit event }`
- `if (selectedItems.isNotEmpty) { dispatch }`

**Regex:** `if\s*\([^)]*\)\s*\{[^}]*\.add\(|if\s*\([^)]*\)\s*\{[^}]*\.dispatch\(`

**Severity:** Critical

**Fix:** Move guard/validation into the BLoC's `mapEventToState`. Widget should always emit the event; BLoC decides validity.

---

### Pattern 2: Data Transformation in Build Method

**Indicator:** Widget transforms/maps data instead of consuming it directly from state

**Examples to catch:**
- `items.map((i) => CustomModel(i)).toList()` in widget
- `final formatted = DateFormat(...).format(date)` in build
- `final total = items.fold(0, (a, b) => a + b.price)`
- `final filtered = items.where((i) => i.status == 'active').toList()`

**Regex:** `(?s)(?:class\s+\w+\s+extends\s+(?:StatelessWidget|StatefulWidget|State<[^>]+>)[^\n]*?build\s*\([^)]*\)\s*\{).*?(?:\b(map|fold|reduce|where|format|parse|transform)\s*\()`

**Notes:** This pattern is intentionally scoped to matches that appear inside `build` methods of classes extending `StatelessWidget`, `StatefulWidget`, or `State<...>` to reduce false positives coming from unrelated code (e.g., SQL string literals or domain layer formatting).

**Severity:** Major

**Fix:** Emit derived data from the BLoC's state instead. Widget receives data pre-shaped for rendering.

---

### Pattern 3: Manual State Coordination

**Indicator:** Widget reads from multiple BLoCs/providers and combines them

**Examples to catch:**
```dart
final authState = context.read<AuthBloc>().state;
final estimationState = context.read<EstimationBloc>().state;
if (authState is Authenticated && estimationState is EstimationsLoaded) {
  // coordinate logic here
}
```

**Regex:** `(?s)context\.read.*?(?:BLoC|Bloc|Provider).*?context\.read.*?(?:BLoC|Bloc|Provider)`

**Notes:** This regex requires two separate `context.read(...)` usages within the same region (e.g., a method or build body) to match. If you prefer to flag any `context.read` outside of builder callbacks, consider a looser pattern or an AST-based check.

**Severity:** Major

**Fix:** Create a higher-level BLoC or use case that orchestrates these flows. Widget should listen to one composed state.

---

### Pattern 4: Navigation Decisions in UI

**Indicator:** Widget decides where to navigate based on business state

**Examples to catch:**
- `if (state.isSuccess) { Navigator.of(context).pushNamed(...) }`
- `if (user.isAdmin) { navigateTo(...) }`
- `Navigator.pop(context)` conditionally in event handler

**Regex:** `if\s*\([^)]*\)\s*\{[^}]*(Navigator|navigation|pushNamed|pop|push)\(`

**Severity:** Critical

**Fix:** Let the BLoC emit `NavigationEvent` or use a navigation layer. Widget should only respond to explicit navigation state.

---

### Pattern 5: State Duplication via setState

**Indicator:** Widget copies BLoC state into local variables

**Examples to catch:**
```dart
String? localValue;
if (state is StateLoaded) {
  localValue = state.value;
}
```

**Regex:** `setState\s*\(\s*\(\)\s*\{[^}]*=\s*state\.|var\s+\w+\s*=\s*state\.`

**Severity:** Major

**Fix:** Consume state directly from BLoC without local copies. Avoid duplication.

---

**Agent Workflow:**

```
For each applicable file:
  1. Read file content
  2. Identify all BlocBuilder/BlocListener instances
  3. Within build methods and event handlers:
     a. Search for guard checks before .add() calls
     b. Search for data transformation/mapping
     c. Search for multiple context.read/watch calls
     d. Search for conditional navigation
     e. Search for state duplication
  4. Extract violations with line numbers and context
  5. Create issue objects with severity and fix suggestions
  6. Return all issues
```

## Suggested Fix

Move validation, mapping, and decision logic into the BLoC, use case, or service layer.

## References

- [Architecture Layers Reference](../references/architecture-layers.md)
- [Clean Presentation & State Derivation](../references/architecture-layers.md)
