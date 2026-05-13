# RULE 5: UI Logic Separation & Clean Presentation

## Rule ID
RULE_5

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

This rule applies to all presentation layer code in `lib/features/**/presentation/` and `lib/app/presentation/`.

---

## For Coding Agents (Prescriptive)

### What Widgets SHOULD Do

✅ **Render State:**
```dart
// Good: Widget just displays what BLoC provides
Widget build(BuildContext context) {
  return BlocBuilder<EstimationBloc, EstimationState>(
    builder: (context, state) {
      if (state is EstimationsLoaded) {
        return ListView.builder(
          itemCount: state.displayItems.length,  // ✅ Already calculated by BLoC
          itemBuilder: (context, index) {
            final item = state.displayItems[index];  // ✅ Simple indexing
            return EstimationCard(estimation: item);
          },
        );
      }
      return const LoadingIndicator();
    },
  );
}
```

✅ **Emit Intents (Events):**
```dart
// Good: Widget just dispatches event, no validation
onPressed: () {
  context.read<EstimationBloc>().add(
    DeleteEstimation(estimationId),  // ✅ BLoC validates
  );
}
```

✅ **Layout Decisions:**
```dart
// Good: Deciding HOW to present is fine
Widget build(BuildContext context) {
  return state.items.isEmpty
    ? EmptyStateWidget()  // ✅ Presentation choice
    : GridView.builder(...);  // ✅ Layout choice
}
```

### What Widgets MUST NOT Do

❌ **Business Validation:**
```dart
// Bad: Widget validates before emitting
onPressed: () {
  if (estimationId != null && estimationId.isNotEmpty) {  // ❌ Guard check
    context.read<EstimationBloc>().add(DeleteEstimation(estimationId));
  }
}

// Good: Always emit, let BLoC validate
onPressed: () {
  context.read<EstimationBloc>().add(
    DeleteEstimation(estimationId),  // ✅ BLoC handles null/empty
  );
}
```

❌ **Derive New State:**
```dart
// Bad: Widget calculates derived values
Widget build(BuildContext context) {
  final items = state.estimations;
  final total = items.fold(0, (sum, e) => sum + e.amount);  // ❌ Calculation
  final displayCount = items.length + (state.isLoading ? 1 : 0);  // ❌ Derivation

  return Text('Total: \$total (displaying $displayCount items)');
}

// Good: BLoC provides derived values
class EstimationState {
  final List<Estimation> estimations;
  final double total;  // ✅ Calculated in BLoC
  final int displayCount;  // ✅ Derived in BLoC
}

Widget build(BuildContext context) {
  return Text('Total: \${state.total} (displaying ${state.displayCount} items)');
}
```

❌ **Cross-State Coordination:**
```dart
// Bad: Widget coordinates multiple BLoCs
Widget build(BuildContext context) {
  final authState = context.watch<AuthBloc>().state;  // ❌
  final dataState = context.watch<DataBloc>().state;  // ❌
  final canEdit = authState.isAdmin && dataState.isEditable;  // ❌ Coordination

  return EditButton(enabled: canEdit);
}

// Good: Create coordinating BLoC or use case
class ScreenBloc {
  final AuthBloc authBloc;
  final DataBloc dataBloc;

  Stream<ScreenState> get state => Rx.combineLatest2(
    authBloc.stream,
    dataBloc.stream,
    (auth, data) => ScreenState(
      canEdit: auth.isAdmin && data.isEditable,  // ✅ Coordination in BLoC
    ),
  );
}

Widget build(BuildContext context) {
  return BlocBuilder<ScreenBloc, ScreenState>(
    builder: (context, state) {
      return EditButton(enabled: state.canEdit);  // ✅ Simple consumption
    },
  );
}
```

❌ **Index Manipulation:**
```dart
// Bad: Widget manipulates indices
Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: items.length + 1,  // ❌ Adding header
    itemBuilder: (context, index) {
      if (index == 0) return HeaderWidget();  // ❌ Special case
      return ItemWidget(items[index - 1]);  // ❌ Index math
    },
  );
}

// Good: BLoC provides composed list
class EstimationState {
  final List<DisplayItem> displayItems;  // ✅ Already includes header
}

Widget build(BuildContext context) {
  return ListView.builder(
    itemCount: state.displayItems.length,  // ✅ Simple length
    itemBuilder: (context, index) {
      return DisplayItemWidget(state.displayItems[index]);  // ✅ Simple index
    },
  );
}
```

### Preferred Patterns

**✅ Composed UI Models:**

BLoC emits states specifically shaped for UI consumption:

```dart
// BLoC provides ready-to-render state
class EstimationListState {
  final List<DisplayItem> items;  // Already includes headers, separators, loading indicators
  final String totalFormatted;  // Already formatted: "\$1,234.56"
  final bool showEmptyState;  // Already decided
  final bool canAddEstimation;  // Already validated
}
```

**✅ Structural Separation:**

Use native layout solutions instead of dynamic builders:

```dart
// Good: Use Sliver structure
Widget build(BuildContext context) {
  return CustomScrollView(
    slivers: [
      SliverAppBar(...),
      if (state.showHeader) SliverToBoxAdapter(child: HeaderWidget()),  // ✅ Structural
      SliverList(delegate: SliverChildBuilderDelegate(...)),
      if (state.isLoading) SliverToBoxAdapter(child: LoadingIndicator()),  // ✅ Structural
    ],
  );
}
```

**✅ View Helpers (for layout only):**

If logic is strictly visual (not reinterpreting state), extract into descriptive getters:

```dart
class _LoginScreenState extends State<LoginScreen> {
  // ✅ OK: Pure layout decision based on screen size
  bool get _shouldShowCompactLayout => MediaQuery.of(context).size.width < 600;

  // ✅ OK: Styling decision
  EdgeInsets get _responsivePadding => _shouldShowCompactLayout
    ? CoreSpacing.space16
    : CoreSpacing.space24;

  // ❌ NOT OK: Would be deriving business value
  // double get _totalPrice => state.items.fold(0, (sum, item) => sum + item.price);
}
```

---

## For Review Agents (Detective)

### Detection Patterns

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

### Pattern 6: Derived Value Calculation

**Indicator:** Widget performs arithmetic or logic that reshapes or reinterprets state data

**Examples to catch:**
- `itemCount: data.length + (isLoading ? 1 : 0)` - Derived list length
- `final total = items.fold(0, (sum, item) => sum + item.price)` - Calculations
- `final displayCount = max(items.length, minItems)` - Value derivation
- `index: baseIndex + offset` - Index manipulation

**Regex:** `(?:itemCount|length|total|count|index):\s*[^;\n]*[+\-*/]|fold\s*\(|reduce\s*\(`

**Severity:** Major

**Fix:** Move derived values into BLoC state. Emit a state object with `displayItems` count already calculated.

---

### Pattern 7: Index Manipulation in UI

**Indicator:** Manually adjusting indices to 'fit' data into a layout

**Examples to catch:**
- `data[index - 1]` - Manual offset
- `index == 0 ? headerWidget : data[index - 1]` - Special casing by index
- `final itemIndex = showLoading ? index - 1 : index`

**Regex:** `\[\s*index\s*[-+]\s*\d+\s*\]|index\s*==\s*0\s*\?|index\s*[-+]=`

**Severity:** Major

**Fix:** BLoC should emit a composed list with headers/footers already inserted. Widget uses simple `data[index]` without manipulation.

---

### Pattern 8: Cross-State Coordination

**Indicator:** Widget compares multiple BLoC states to derive a single UI result

**Examples to catch:**
```dart
final authState = context.watch<AuthBloc>().state;
final dataState = context.watch<DataBloc>().state;
final canEdit = authState.isAdmin && dataState.isEditable;
```

**Regex:** `(?:final|var|bool|int|String)\s+\w+\s*=\s*\w+State.*&&.*\w+State`

**Severity:** Major

**Fix:** Create a higher-level BLoC or use case that listens to both states and emits a combined `ScreenState` with `canEdit` already determined.

---

### Pattern 9: Complex Conditionals for Rendering

**Indicator:** Nested ternary operators or long if-else chains to decide which widget to render

**Examples to catch:**
- `isLoading ? LoadingWidget() : hasError ? ErrorWidget() : data.isEmpty ? EmptyWidget() : ContentWidget()`
- Multiple levels of ternary nesting
- Long if-else chains based on state combinations

**Regex:** `\?\s*\w+\([^)]*\)\s*:\s*\w+\([^)]*\)\s*:\s*\w+\(`

**Severity:** Minor

**Fix:** BLoC emits distinct state types (`LoadingState`, `ErrorState`, `EmptyState`, `LoadedState`). Widget pattern matches on state type.

---

**Agent Workflow:**

```
For each applicable file:
  1. Read file content
  2. Identify all BlocBuilder/BlocListener instances
  3. Within build methods and event handlers:
     a. Search for guard checks before .add() calls (Pattern 1)
     b. Search for data transformation/mapping (Pattern 2)
     c. Search for multiple context.read/watch calls (Pattern 3)
     d. Search for conditional navigation (Pattern 4)
     e. Search for state duplication (Pattern 5)
     f. Search for arithmetic/derived value calculations (Pattern 6)
     g. Search for index manipulation (Pattern 7)
     h. Search for cross-state coordination (Pattern 8)
     i. Search for complex conditional rendering (Pattern 9)
  4. Extract violations with line numbers and context
  5. Create issue objects with severity and fix suggestions
  6. Return all issues
```

## Summary: Suggested Fixes

Move all business logic, validation, coordination, and state derivation into the BLoC, use case, or service layer. Keep widgets as passive viewers that only decide HOW to present data, not WHAT data to present.

## References

- [RULE_5 Gist: UI & Business Logic Separation](https://gist.github.com/ripplearcgit/f190fecc8f7124e511cb01283f9fbc31)
- [Architecture Layers Reference](../references/architecture-layers.md)
- Related: RULE_2 (Naming Conventions) - ensures classes in right layer

## Notes

This rule combines two related concepts:
1. **Business Logic Separation** (original RULE_5) - No validation, coordination, or decisions in UI
2. **State Derivation** (original RULE_12) - No calculations, transformations, or derived values in UI

Both serve the same goal: keeping UI as passive viewers that render pre-shaped state.
