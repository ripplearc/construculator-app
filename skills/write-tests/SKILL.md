---
name: write-tests
description: |
  Stage 4: Testing - Write unit tests (domain, data, blocs) and widget tests (pages, widgets).
  Uses REAL implementations within feature; fakes only at I/O boundaries and library dependencies.

  Trigger: "write tests", "create unit tests", "create widget tests"

disable-model-invocation: false
---

# Write Tests Skill

**Verb:** Write unit and widget tests using real implementations.

**Input:** Context from coding skills — classes created, file paths, business logic.

> If any pattern below is unclear or you need a concrete Dart implementation, read `skills/write-tests/REFERENCE.md`.

## 1. Implementation Rules

1. **Use REAL implementations within the same feature** — UseCase, BLoC, Repository, and DataSource tests should use the real feature code from the module.
2. **Fake only external I/O and library dependencies** — Use fakes for database/network wrappers and repositories from other libraries.
3. **Keep tests faithful** — Prefer high-fidelity setup over mocks or method-call assertions.

**Component Guide:**

| Component Type | Same Feature | Other Library | External I/O |
|----------------|--------------|---------------|--------------|
| **UseCase** | ✅ Real | N/A | N/A |
| **BLoC** | ✅ Real | N/A | N/A |
| **Repository** | ✅ Real | ❌ Fake | N/A |
| **DataSource** | ✅ Real | N/A | N/A |
| **Wrapper** | N/A | N/A | ❌ Fake |

## 2. Unit Test Patterns

### UseCase Tests

Init `FakeSupabaseWrapper` + `FakeAppBootstrapFactory`, pass to `FeatureTestModule`, then get the real UseCase from `Modular`. Test success by seeding fake state; test failure by setting `fakeSupabase.shouldThrowOnX = true`. Verify `Either<Failure, T>` results. Always call `Modular.destroy()` in `tearDown`.

### BLoC Tests

Use the `bloc_test` package. Get the real BLoC from `Modular`. Use `blocTest` with `build`, `act`, and `expect`. Since BLoC states implement Equatable, prefer full object comparison in `expect` — e.g. `FeatureSuccess(data: expectedData)` — rather than `isA<>().having()`. Only fall back to `isA<>().having()` when the state does not implement Equatable or you intentionally want to match a partial subset of properties.

### Repository/DataSource Tests

Test real coordination: RepositoryImpl delegates to DataSource; DataSource calls `SupabaseWrapper` methods; exceptions map to the correct Failure subtype.

## 3. Widget Test Patterns

### Page Tests

Create a `makeTestableWidget` helper that wraps the page in `BlocProvider` + `MaterialApp` with `createTestTheme()`, `locale: const Locale('en')`, and `AppLocalizations` delegates. Seed `fakeSupabase` before pumping. Use `pumpAndSettle()` after pump. Find text via `lookupAppLocalizations(const Locale('en'))` — never hardcoded strings (Localization).

### Widget Interaction Tests

Pump the page, interact using `tester.enterText` (find by key, Widget Test Finders) and `tester.tap` (find by `l10n` string), `pumpAndSettle()` after each action, then assert the resulting state.

## 4. Test Module Setup

Prefer `Modular.init({Feature}Module(appBootstrap))` directly — pass the real feature module with a fake bootstrap built via `FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase)`. Only wrap in an inline module class when the test needs extra test-specific modules (e.g. `RouterTestModule`, `ClockTestModule`) that the feature module doesn't already import. In `tearDown`, always call `fakeSupabase.reset()` then `Modular.destroy()`.

## 5. Anti-Patterns (Avoid)

| ❌ Flaky Pattern | ✅ Correct Pattern |
|-----------------|-------------------|
| `await Future.delayed(Duration.zero)` | `await tester.pumpAndSettle()` |
| `await tester.pump()` repeatedly | `await tester.pumpAndSettle()` once |
| `await tester.pump(Duration(seconds: 5))` | Configure fake to complete immediately |
| `find.byType(Button)` (positional) | `find.byKey(Key('button_key'))` or `find.text(l10n.label)` |
| `findsNWidgets(3)` (count-based) | `find.byKey` for specific widgets |
| Faking repo in same feature | Use REAL repo with FakeSupabaseWrapper |
| Using mocks (`when(...).thenReturn(...)`) | Use fakes that implement interface |
| `isA<FeatureSuccess>().having((s) => s.data, ...)` | `FeatureSuccess(data: expectedData)` — full object via Equatable |
| `expect(result.length, 2)` + per-item property checks | `expect(result, [item1, item2])` — full list via Equatable |

For async loading states, use `fakeSupabase.shouldDelayOperations = true` + `Completer` — not `Future.delayed`.

## 6. File Structure

Mirror implementation structure in `test/features/{feature}/`:

```
test/features/{feature}/
├── units/
│   ├── blocs/{bloc}_test.dart
│   ├── domain/usecases/{usecase}_test.dart
│   ├── data/
│   │   ├── repositories/{repo}_test.dart
│   │   └── data_source/{datasource}_test.dart
│   └── fakes/fake_{repository}_test.dart (for library repos only)
├── widgets/
│   ├── pages/{page}_test.dart
│   └── widgets/{widget}_test.dart
└── accessibility/
    └── {page}_a11y_test.dart
```

**File naming:** `{source_file}_test.dart`

## 7. Accessibility Testing

Write a11y tests for pages/widgets with interactive elements. Use `setupA11yTest(tester)` + `expectMeetsTapTargetAndLabelGuidelinesForEachTheme` from the test harness. Verifies tap targets (48×48 min), semantic labels, and contrast across light/dark themes. File in `test/features/{feature}/accessibility/`. See `docs/Testing/Accessibility-Testing.md` for the full harness.

## 8. Common Patterns

See `skills/write-tests/REFERENCE.md` for Dart examples: invalid inputs, error states, authentication, and loading states.

## References

- **Test Double Pattern:** `skills/rules/03-test-double-pattern.md` — Use fakes, never mocks
- **Widget Test Finders:** `skills/rules/08-widget-test-finders.md` — Semantic finders
- **Unit Test Behavior:** `skills/rules/09-unit-test-behavior.md` — Test behavior, not implementation
- **Testing Docs:** `docs/Testing/Fakes.md`, `docs/Testing/Directories.md`, `docs/Testing/Accessibility-Testing.md`
- **Examples:** `test/features/auth/units/blocs/`, `test/features/auth/widgets/pages/`
- **Next:** `write-tests-golden` (gated — screenshot tests for UI changes)
