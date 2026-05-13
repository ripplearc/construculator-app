---
name: code-presentation
description: |
  Stage 3: Coding (Presentation Layer) - Write Pages, BLoCs, and Widgets.
  Presentation layer handles UI, state coordination, and user interaction with zero business logic.

  ⚠️ INVOCATION: Only use when the ticket touches the presentation layer (UI, screens, BLoC state management).

  Trigger: Any of the following phrases exactly as written, without variations: "write UI code", "implement presentation layer", "create page", "create bloc"

disable-model-invocation: false
---

# Code Presentation Skill

**Verb:** Write presentation layer code (Pages, BLoCs, Widgets).

**Input:** Context from `plan-implementation` — page names, BLoC states, widget hierarchy.

If the input context from `plan-implementation` is incomplete or missing, respond with an error message specifying the missing details before writing code.

## 1. Class Overview

| Class Type | Naming (RULE_2) | Purpose | Location |
|------------|-----------------|---------|----------|
| **Page** | `{Feature}Page` | Top-level screen with route; contains BLoC provider | `presentation/pages/{feature}_page.dart` |
| **BLoC** | `{Feature}Bloc` | State coordinator; emits states based on events | `presentation/bloc/{feature}_bloc/{feature}_bloc.dart` |
| **Event** | `{Feature}Event` (sealed) | User actions or lifecycle events | `presentation/bloc/{feature}_bloc/{feature}_event.dart` |
| **State** | `{Feature}State` (sealed) | UI state representations | `presentation/bloc/{feature}_bloc/{feature}_state.dart` |
| **Widget** | `{Purpose}Widget` | Reusable UI component | `presentation/widgets/{purpose}_widget.dart` |

## 2. Page Pattern

**Purpose:** Top-level screen that provides BLoC and builds UI tree.

**Access via BuildContext extension:**
- **Localization (RULE_10):** `context.l10n.keyName` (not `S.of(context)`)
- **Colors:** `context.colorTheme.primary`, `context.colorTheme.pageBackground`
- **Typography:** `context.textTheme.bodyMediumRegular`, `context.textTheme.titleLargeBold`

**UI Rules:**
- **RULE_4:** Use CoreUI components ONLY — never `Material` widgets directly
- **RULE_10:** All text via `context.l10n.keyName` — no hardcoded strings
- Pages are **passive** — they display state from BLoC; they don't decide what state means

**BLoC access (preferred):** Prefer resolving BLoCs via `BuildContext` instead of `Modular.get`. This keeps wiring explicit and works well with `BlocProvider`.

Two recommended approaches:

1. Inline usage for simple callbacks:

```dart
onTabSelected: (index) => context.read<AppShellBloc>().add(AppShellTabSelected(index)),
```

2. Field resolution in `didChangeDependencies` (preferred when a `BlocProvider` is above the Page):

Resolve the BLoC in `didChangeDependencies` (not in `build`) to avoid repeated lookups and to satisfy lints that forbid resolving dependencies during build.

If your app does not provide the BLoC via `BlocProvider`, fall back to module
registration and resolve as a class field:
  `final _bloc = Modular.get<FeatureBloc>();`
Never call `Modular.get` inside `build()` — violates `forbid_modular_get_outside_module`.

**Routing (three-tier model):**
- **Tab switching** (within shell): Dispatch BLoC events (e.g. `context.read<AppShellBloc>().add(AppShellTabSelected(index))`) — handled by the shell's BLoC; widgets do not have to call `Navigator.push/pop` to switch tabs
- **Full-screen navigation** (above shell): `Modular.get<AppRouter>().push(...)` / `.pop()` — replaces entire shell
- **In-tab drill-downs** (within tab): `Navigator.of(context).push(...)` / `.pop()` — preserves tab state and other tabs
  ⚠️ Never use AppRouter for tab-switching or in-tab navigation — it resets tab state and navigators.

## 3. BLoC Pattern

**Purpose:** Coordinate UI state; handle events; emit states. BLoC is NOT a business rule engine.

**Structure:**
```
bloc/{feature}_bloc/
├── {feature}_bloc.dart       # BLoC class with event handlers
├── {feature}_event.dart       # Sealed event classes
└── {feature}_state.dart       # Sealed state classes
```

**State Management Rules:**
- **RULE_12:** State derivation happens HERE, not in widgets (e.g., `total`, `isValid`, `filteredItems`)
- **RULE_5:** BLoC orchestrates UseCases; doesn't implement business logic
- Events: User actions (`SubmitPressed`, `FieldChanged`) or lifecycle (`PageLoaded`)
- States: UI representations (`Loading`, `Success`, `Error`)
- Use `emit()` to transition states

**Error handling:** Catch UseCase failures; emit error states with user-friendly messages (via RULE_10 localization).

## 4. Widget Pattern

**Purpose:** Reusable UI components; receive data via constructor; no state management.

**Widget Rules:**
- **RULE_4:** CoreUI components only (from `ripplearc_coreui` package)
- **RULE_10:** Localized text via `context.l10n.keyName`
- **RULE_5:** Zero logic — widgets are **dumb presenters**
- Use `context.colorTheme` for colors, `context.textTheme` for typography
- Prefer `const` constructors for performance
- Extract complex UI trees into named widgets for readability

**Forbidden in widgets:**
- Business validation (`if (id != null) { bloc.add(...) }`)
- State derivation (`total = items.fold(...)`)
- Cross-field coordination
- Direct UseCase calls
- Hardcoded colors/text (use `context.colorTheme`, `context.l10n`)

## 5. Dependency Registration

Add to `lib/features/{feature}/{feature}_module.dart`:

```dart
void _registerDependencies(Injector i) {
  // BLoCs (transient — new instance per request)
  i.add<{Feature}Bloc>(() => {Feature}Bloc(useCase: i()));
}
```

## 6. Layer Boundaries (RULE_5)

| ❌ Presentation MUST NOT | ✅ Presentation CAN |
|-------------------------|-------------------|
| Implement business logic (validation, calculations) | Call UseCases (orchestrate) |
| Import data layer (`RepositoryImpl`, `DataSource`) | Import domain (`UseCase`, `Entity`, `Failure`) |
| Derive state in widgets (`build` method calculations) | Derive state in BLoC (`emit` computed states) |
| Hardcode strings/colors | Use `context.l10n`, `context.colorTheme`, `context.textTheme` |
| Use Material widgets directly | Import CoreUI (`ripplearc_coreui`) |

## Output Files

- `lib/features/{feature}/presentation/pages/{feature}_page.dart`
- `lib/features/{feature}/presentation/bloc/{feature}_bloc/{feature}_bloc.dart`
- `lib/features/{feature}/presentation/bloc/{feature}_bloc/{feature}_event.dart`
- `lib/features/{feature}/presentation/bloc/{feature}_bloc/{feature}_state.dart`
- `lib/features/{feature}/presentation/widgets/{purpose}_widget.dart` (if needed)
- Updated: `lib/features/{feature}/{feature}_module.dart`

## Priority Rules (Critical to Follow)

### 🔴 Non-Negotiable
1. **Zero business logic** — Presentation must not implement business rules; always call UseCases (RULE_5)
2. **Localization & Theming** — All user-facing text via `context.l10n`; use `context.colorTheme` and `context.textTheme` for colors/typography (RULE_10)
3. **CoreUI Only** — Use `ripplearc_coreui` components; avoid direct `Material` widgets (RULE_4)

### 🟡 Core Patterns (Always Apply)
4. **Pages are passive** — Pages display BLoC-provided state and do not contain logic
5. **BLoC coordinates state** — Derive computed values and state transitions in BLoC (RULE_12)
6. **Routing (three-tier model):**
   - Tab switching (within shell): `context.read<AppShellBloc>().add(AppShellTabSelected(index))`
   - Full-screen (above shell): `_router.push(...)` — resolve as `final _router = Modular.get<AppRouter>();` class field
   - In-tab drill-downs: `Navigator.of(context).push(...)` / `.pop()` — never AppRouter here
7. **Testable widgets** — Widgets are dumb presenters; prefer `const` constructors and constructor-based inputs

## References

- **RULE_4:** `skills/rules/04-coreui-components.md` — CoreUI components
- **RULE_5:** `skills/rules/05-ui-business-separation.md` — No business logic in UI + State derivation in BLoC
- **RULE_7:** `skills/rules/07-self-documenting-code.md` — Comments explain why
- **RULE_10:** `skills/rules/10-localization.md` — All user-facing text
- **CoreUI API:** `skills/references/coreui-api.md`
- **Examples:** `lib/features/auth/presentation/`, `lib/features/project/presentation/`
- `write-tests` skill — Widget tests for pages

