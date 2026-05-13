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

**Setup:** Use Modular with real implementations; fake only `SupabaseWrapper` and library repositories.

```dart
setUpAll(() {
  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: FakeSupabaseWrapper(clock: FakeClockImpl()),
  );
  Modular.init(FeatureTestModule(appBootstrap));

  fakeSupabase = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
  useCase = Modular.get<{Verb}{Noun}UseCase>(); // REAL UseCase with REAL Repository
});
```

**Test both success and failure:**
- Configure `fakeSupabase` state for success path
- Configure `fakeSupabase.shouldThrowOnX = true` for error path
- Verify `Either<Failure, T>` results

### BLoC Tests

**Use `bloc_test` package:**

```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<{Feature}Bloc, {Feature}State>(
  'emits [Loading, Success] when operation succeeds',
  build: () => Modular.get<{Feature}Bloc>(), // REAL BLoC
  act: (bloc) => bloc.add(EventTriggered()),
  expect: () => [
    isA<{Feature}Loading>(),
    isA<{Feature}Success>().having((s) => s.data, 'data', expectedData),
  ],
);
```

**Key:** Test state transitions; avoid testing implementation details like method call counts.

### Repository/DataSource Tests

**Test REAL coordination logic:**
- RepositoryImpl delegates to DataSource ✅
- DataSource calls `SupabaseWrapper` methods ✅
- Error mapping: exceptions → Failures ✅

## 3. Widget Test Patterns

### Page Tests

**Setup:** Create test module + helper to wrap widget.

```dart
Widget makeTestableWidget({required Widget child}) {
  return BlocProvider<{Feature}Bloc>(
    create: (context) => Modular.get<{Feature}Bloc>(),
    child: MaterialApp(
      theme: createTestTheme(),
      home: child,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}
```

**Test pattern:**
```dart
testWidgets('displays data when loaded', (tester) async {
  // Arrange: Set up fake state
  fakeSupabase.addTableData('table_name', [{ /* data */ }]);

  // Act: Render page
  await tester.pumpWidget(makeTestableWidget(child: PageWidget()));
  await tester.pumpAndSettle();

  // Assert: Verify UI (RULE_10: use l10n for text, not hardcoded strings)
  final l10n = lookupAppLocalizations(const Locale('en'));
  expect(find.text(l10n.expectedLabel), findsOneWidget);
  expect(find.byKey(const Key('data_key')), findsOneWidget);
});
```

**Why use `l10n` in tests:**
- **Refactor-safe** — Tests survive UX copy changes
- **Verifies localization** — Ensures `context.l10n` is wired correctly
- **Follows RULE_10** — No hardcoded strings, even in tests

**Access localization in tests:**
```dart
final l10n = lookupAppLocalizations(const Locale('en'));
expect(find.text(l10n.submitButton), findsOneWidget);
```

### Widget Interaction Tests

```dart
testWidgets('button tap triggers event', (tester) async {
  await tester.pumpWidget(makeTestableWidget(child: PageWidget()));
  await tester.pumpAndSettle();

  // Interact (RULE_4: CoreTextField, RULE_8: semantic key)
  await tester.enterText(find.byKey(const Key('input_field')), 'input');
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.submitButton));
  await tester.pumpAndSettle();

  // Verify result
  expect(find.text(l10n.successMessage), findsOneWidget);
});
```

## 4. Test Module Setup

**Pattern:** Import real feature module + test-specific modules.

```dart
class FeatureTestModule extends Module {
  final AppBootstrap appBootstrap;
  FeatureTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),       // FakeAppRouter
    ClockTestModule(),        // FakeClockImpl
    FeatureModule(appBootstrap), // REAL implementations
  ];
}
```

**In setUpAll:**
```dart
setUpAll(() {
  fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());

  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
  );

  Modular.init(FeatureTestModule(appBootstrap));
});

tearDownAll(() => Modular.destroy());
```

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

**Why avoid `Future.delayed(Duration.zero)`?**
- Creates flakiness; `pumpAndSettle()` handles frames automatically
- If async, use `fakeSupabase.shouldDelayOperations = true` + `Completer`

**Why avoid count-based finders?**
- Brittle; breaks when UI changes
- Use semantic finders: `byKey`, `text`, `byType` (sparingly)

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

**When:** Write a11y tests for pages/widgets with interactive elements (buttons, forms, navigation).

**Pattern:** Use test harness from `docs/Testing/Accessibility-Testing.md`:

```dart
testWidgets('PageWidget meets a11y guidelines', (tester) async {
  await setupA11yTest(tester);

  await expectMeetsTapTargetAndLabelGuidelinesForEachTheme(
    tester,
    (theme) => const PageWidget(),
    find.byType(PageWidget),
  );
});
```

**Verifies:**
- Tap target sizes (48x48 minimum)
- Semantic labels for screen readers
- Text contrast (light + dark themes)

**File location:** `test/features/{feature}/accessibility/{page}_a11y_test.dart`

**Reference:** `docs/Testing/Accessibility-Testing.md` — Comprehensive a11y testing guide

## 9. Common Patterns

### Testing Invalid Inputs

```dart
testWidgets('shows validation error for empty input', (tester) async {
  await renderPage(tester);
  await tester.enterText(find.byKey(const Key('input_field')), '');

  expect(find.text(l10n.requiredFieldError), findsOneWidget);
});

testWidgets('handles null or unsupported values safely', (tester) async {
  fakeSupabase.setResponse(null);

  await renderPage(tester);

  expect(find.text(l10n.genericError), findsOneWidget);
});
```

### Testing Error States

```dart
testWidgets('shows error when operation fails', (tester) async {
  fakeSupabase.shouldThrowOnInsert = true;
  fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;

  await renderPage(tester);
  await tapSubmitButton(tester);

  expect(find.text(l10n.connectionError), findsOneWidget);
});
```

### Testing Authentication

```dart
setUp(() {
  final user = FakeUser(id: 'user-123', email: 'test@example.com');
  fakeSupabase.setCurrentUser(user);
});
```

### Testing Loading States

```dart
testWidgets('shows loading indicator during fetch', (tester) async {
  fakeSupabase.shouldDelayOperations = true;
  fakeSupabase.completer = Completer();

  await renderPage(tester);

  // Loading state (RULE_4: CoreUI, RULE_8: semantic key)
  expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

  // Complete operation
  fakeSupabase.completer!.complete();
  await tester.pumpAndSettle();

  // Success state
  expect(find.byKey(const Key('loading_indicator')), findsNothing);
  expect(find.text('Data Loaded'), findsOneWidget);
});
```

## Key Principles

1. **Use real implementations** — Within same feature, test real UseCases/BLoCs/Repositories/DataSources
2. **Fake at boundaries** — `FakeSupabaseWrapper` (I/O), `FakeXRepository` (library dependencies)
3. **Use Modular DI** — Initialize with test modules; get instances from Modular
4. **Semantic finders** — `byKey`, `text(l10n.xxx)` — never `findsNWidgets` or positional
5. **No flaky patterns** — `pumpAndSettle()` instead of `Future.delayed(Duration.zero)`
6. **Test both paths** — Success AND error states
7. **Use `bloc_test`** — For BLoC state transition testing

## References

- **RULE_3:** `skills/rules/03-test-double-pattern.md` — Use fakes, never mocks
- **RULE_8:** `skills/rules/08-widget-test-finders.md` — Semantic finders
- **RULE_9:** `skills/rules/09-unit-test-behavior.md` — Test behavior, not implementation
- **Testing Docs:** `docs/Testing/Fakes.md`, `docs/Testing/Directories.md`, `docs/Testing/Accessibility-Testing.md`
- **Examples:** `test/features/auth/units/blocs/`, `test/features/auth/widgets/pages/`
- **Next:** `write-tests-golden` (gated — screenshot tests for UI changes)
