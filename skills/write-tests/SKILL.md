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

Create a `makeTestableWidget` helper that wraps the page in `BlocProvider` + `MaterialApp` with `createTestTheme()`, `locale: const Locale('en')`, and `AppLocalizations` delegates. Seed `fakeSupabase` before pumping. Use `pumpAndSettle()` after pump. Find text via `lookupAppLocalizations(const Locale('en'))` — never hardcoded strings (RULE_10).

### Widget Interaction Tests

Pump the page, interact using `tester.enterText` (find by key, RULE_8) and `tester.tap` (find by `l10n` string), `pumpAndSettle()` after each action, then assert the resulting state.

## 4. Test Module Setup

`FeatureTestModule` imports `RouterTestModule`, `ClockTestModule`, and the real `FeatureModule(appBootstrap)`. In `setUp`, create `FakeSupabaseWrapper`, build `FakeAppBootstrapFactory.create(supabaseWrapper: fakeSupabase)`, and call `Modular.init(FeatureTestModule(appBootstrap))`. In `tearDown`, call `Modular.destroy()`.

## 5. Faking Decision Tree

```
Is it an external I/O service (database, network)?
├─ YES → Use FakeSupabaseWrapper (or wrapper fake)
└─ NO → Continue...

Is it a repository from ANOTHER library?
├─ YES → Use FakeRepository (e.g., FakeAuthRepository)
└─ NO → Continue...

Is it from SAME feature?
├─ UseCase → ✅ Real
├─ BLoC → ✅ Real
├─ Repository → ✅ Real
└─ DataSource → ✅ Real
```

## 6. Anti-Patterns (Avoid)

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

## 7. File Structure

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

## 8. Accessibility Testing

Write a11y tests for pages/widgets with interactive elements. Use `setupA11yTest(tester)` + `expectMeetsTapTargetAndLabelGuidelinesForEachTheme` from the test harness. Verifies tap targets (48×48 min), semantic labels, and contrast across light/dark themes. File in `test/features/{feature}/accessibility/`. See `docs/Testing/Accessibility-Testing.md` for the full harness.

## 9. Common Patterns

- **Invalid inputs** — Enter empty/null value; assert `l10n.requiredFieldError` or `l10n.genericError` appears.
- **Error states** — Set `fakeSupabase.shouldThrowOnInsert = true` + `insertExceptionType`; assert error message via `l10n`.
- **Authentication** — Seed `fakeSupabase.setCurrentUser(FakeUser(...))` in `setUp`.
- **Loading states** — Set `shouldDelayOperations = true` + `Completer`; assert loading key present; complete; assert success state.

## Key Principles

1. **Use real implementations** — Within same feature, test real UseCases/BLoCs/Repositories/DataSources
2. **Fake at boundaries** — `FakeSupabaseWrapper` (I/O), `FakeXRepository` (library dependencies)
3. **Use Modular DI** — Initialize with test modules; get instances from Modular
4. **Semantic finders** — `byKey`, `text(l10n.xxx)` — never `findsNWidgets` or positional
5. **No flaky patterns** — `pumpAndSettle()` instead of `Future.delayed(Duration.zero)`
6. **Test both paths** — Success AND error states
7. **Use `bloc_test`** — For BLoC state transition testing
8. **Full object comparisons** — Entities, DTOs, and states use Equatable; assert `expect(result, expected)` and `expect(list, [a, b, c])` directly instead of drilling into individual properties

## References

- **RULE_3:** `skills/rules/03-test-double-pattern.md` — Use fakes, never mocks
- **RULE_8:** `skills/rules/08-widget-test-finders.md` — Semantic finders
- **RULE_9:** `skills/rules/09-unit-test-behavior.md` — Test behavior, not implementation
- **Testing Docs:** `docs/Testing/Fakes.md`, `docs/Testing/Directories.md`, `docs/Testing/Accessibility-Testing.md`
- **Examples:** `test/features/auth/units/blocs/`, `test/features/auth/widgets/pages/`
- **Next:** `write-tests-golden` (gated — screenshot tests for UI changes)
