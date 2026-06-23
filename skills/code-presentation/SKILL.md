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

| Class Type | Naming | Purpose | Location |
|------------|-----------------|---------|----------|
| **Page** | `{Feature}Page` | Top-level screen with route; contains BLoC provider | `presentation/pages/{feature}_page.dart` |
| **BLoC** | `{Feature}Bloc` | State coordinator; emits states based on events | `presentation/bloc/{feature}_bloc/{feature}_bloc.dart` |
| **Event** | `{Feature}Event` (sealed) | User actions or lifecycle events | `presentation/bloc/{feature}_bloc/{feature}_event.dart` |
| **State** | `{Feature}State` (sealed) | UI state representations | `presentation/bloc/{feature}_bloc/{feature}_state.dart` |
| **Widget** | `{Purpose}Widget` | Reusable UI component | `presentation/widgets/{purpose}_widget.dart` |

## 2. Page Pattern

Top-level screen; provides BLoC; builds UI tree. Pages are **passive** — they display state, they don't decide what it means.

**BuildContext extensions** (always use these — never hardcode):
- Localization: `context.l10n.keyName` (not `S.of(context)`)
- Colors: `context.colorTheme.primary` / `.pageBackground`
- Typography: `context.textTheme.bodyMediumRegular` / `.titleLargeBold`

**BLoC access:** Prefer `context.read<FeatureBloc>()` (inline callbacks) or resolve as a field in `didChangeDependencies` when a `BlocProvider` is above the Page. Fall back to `final _bloc = Modular.get<FeatureBloc>();` as a class field only if no `BlocProvider` exists. **Never call `Modular.get` inside `build()`** — violates `forbid_modular_get_outside_module`.

## 3. BLoC Pattern

Coordinate UI state; handle events; emit states. BLoC is **not** a business rule engine.

- **State Derivation:** State derivation lives here, not in widgets (`total`, `isValid`, `filteredItems`).
- **UI / Business Separation:** BLoC orchestrates UseCases; never implements business logic.
- Events = user actions (`SubmitPressed`) or lifecycle (`PageLoaded`); States = UI representations (`Loading`, `Success`, `Error`). Transition with `emit()`.
- **Error handling:** Catch UseCase failures; emit error states with localized messages (Localization).

## 4. Widget Pattern

Reusable UI components; data via constructor; no state management. Widgets are **dumb presenters** (UI / Business Separation) — zero business logic, no state derivation, no UseCase calls. Use CoreUI only (CoreUI Components), `context.l10n` for text (Localization), `context.colorTheme` / `context.textTheme` for styling. Prefer `const` constructors.

## 5. Dependency Registration

In `{feature}_module.dart`, register BLoCs as transient: `i.add<{Feature}Bloc>(() => {Feature}Bloc(useCase: i()));`. See `code-domain` skill for canonical module pattern.

## 6. Layer Boundaries (UI / Business Separation)

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
1. **Zero business logic** — Presentation must not implement business rules; always call UseCases (UI / Business Separation)
2. **Localization & Theming** — All user-facing text via `context.l10n`; use `context.colorTheme` and `context.textTheme` for colors/typography (Localization)
3. **CoreUI Only** — Use `ripplearc_coreui` components; avoid direct `Material` widgets (CoreUI Components)

### 🟡 Core Patterns (Always Apply)
4. **Pages are passive** — Pages display BLoC-provided state and do not contain logic
5. **BLoC coordinates state** — Derive computed values and state transitions in BLoC (State Derivation)
6. **Routing (three-tier model):**
   - Tab switching (within shell): receive `AppShellBloc` as a constructor prop and call `appShellBloc.add(AppShellTabSelected(tab))` — `AppShellBloc` is not in the widget tree as a `BlocProvider`, so `context.read<AppShellBloc>()` will not work
   - Full-screen (above shell): `_router.push(...)` — resolve as `final _router = Modular.get<AppRouter>();` class field
   - In-tab drill-downs: `Navigator.of(context).push(...)` / `.pop()` — never AppRouter here
   - ⚠️ **Never use AppRouter for tab-switching or in-tab navigation** — it resets tab state and navigators.
7. **Testable widgets** — Widgets are dumb presenters; prefer `const` constructors and constructor-based inputs

## References

- **CoreUI Components:** `skills/rules/04-coreui-components.md` — CoreUI components
- **UI / Business Separation:** `skills/rules/05-ui-business-separation.md` — No business logic in UI + State derivation in BLoC
- **Self-Documenting Code:** `skills/rules/07-self-documenting-code.md` — Comments explain why
- **Localization:** `skills/rules/10-localization.md` — All user-facing text
- **State Derivation:** `skills/rules/12-state-derivation.md` — Derive in BLoC, not widgets
- **CoreUI API:** `skills/references/coreui-api.md`
- **Examples:** `lib/features/auth/presentation/`, `lib/features/project/presentation/`
- `write-tests` skill — Widget tests for pages

