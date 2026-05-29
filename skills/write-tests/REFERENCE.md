# Write Tests — Code Reference

Read this file when the pattern descriptions in SKILL.md or the rule files are not clear enough.

## UseCase Test Setup

```dart
setUp(() {
  fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
  );
  Modular.init(FeatureTestModule(appBootstrap));

  useCase = Modular.get<{Verb}{Noun}UseCase>(); // REAL UseCase with REAL Repository
});

tearDown(() => Modular.destroy());
```

## BLoC Test

```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<{Feature}Bloc, {Feature}State>(
  'emits [Loading, Success] when operation succeeds',
  build: () => Modular.get<{Feature}Bloc>(), // REAL BLoC
  act: (bloc) => bloc.add(EventTriggered()),
  // States implement Equatable — prefer full object comparison over isA<>().having()
  expect: () => [
    {Feature}Loading(),
    {Feature}Success(data: expectedData),
  ],
);
```

## makeTestableWidget Helper

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

## Page Test Pattern

```dart
testWidgets('displays data when loaded', (tester) async {
  fakeSupabase.addTableData('table_name', [{ /* data */ }]);

  await tester.pumpWidget(makeTestableWidget(child: PageWidget()));
  await tester.pumpAndSettle();

  final l10n = lookupAppLocalizations(const Locale('en'));
  expect(find.text(l10n.expectedLabel), findsOneWidget);
  expect(find.byKey(const Key('data_key')), findsOneWidget);
});
```

## Widget Interaction Test

```dart
testWidgets('button tap triggers event', (tester) async {
  await tester.pumpWidget(makeTestableWidget(child: PageWidget()));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('input_field')), 'input');
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.submitButton));
  await tester.pumpAndSettle();

  expect(find.text(l10n.successMessage), findsOneWidget);
});
```

## Test Module

```dart
class FeatureTestModule extends Module {
  final AppBootstrap appBootstrap;
  FeatureTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    RouterTestModule(),            // FakeAppRouter
    ClockTestModule(),             // FakeClockImpl
    FeatureModule(appBootstrap),   // REAL implementations
  ];
}

setUp(() {
  fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final appBootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
  );
  Modular.init(FeatureTestModule(appBootstrap));
});

tearDown(() => Modular.destroy());
```

## Accessibility Test

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

## Testing Invalid Inputs

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

## Testing Error States

```dart
testWidgets('shows error when operation fails', (tester) async {
  fakeSupabase.shouldThrowOnInsert = true;
  fakeSupabase.insertExceptionType = SupabaseExceptionType.socket;

  await renderPage(tester);
  await tapSubmitButton(tester);

  expect(find.text(l10n.connectionError), findsOneWidget);
});
```

## Testing Authentication

```dart
setUp(() {
  final user = FakeUser(id: 'user-123', email: 'test@example.com');
  fakeSupabase.setCurrentUser(user);
});
```

## Testing Loading States

```dart
testWidgets('shows loading indicator during fetch', (tester) async {
  fakeSupabase.shouldDelayOperations = true;
  fakeSupabase.completer = Completer();

  await renderPage(tester);

  expect(find.byKey(const Key('loading_indicator')), findsOneWidget);

  fakeSupabase.completer!.complete();
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('loading_indicator')), findsNothing);
  final l10n = lookupAppLocalizations(const Locale('en'));
  expect(find.text(l10n.dataLoaded), findsOneWidget);
});
```
