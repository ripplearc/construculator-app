import 'package:construculator/features/estimation/presentation/widgets/discard_line_guard.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

typedef _Form = ({bool hasUnsavedChanges, bool isSaving});

class _FakeFormCubit extends Cubit<_Form> {
  _FakeFormCubit(super.initialState);

  void finishSave() =>
      emit((hasUnsavedChanges: state.hasUnsavedChanges, isSaving: false));
}

void main() {
  const fieldKey = Key('field');
  const sheetKey = Key('sheet');
  late FocusNode field;
  late _FakeFormCubit form;

  Future<void> openGuardedSheet(
    WidgetTester tester, {
    required bool isOwnKeyboardUp,
    required bool hasUnsavedChanges,
    bool isSaving = false,
    bool padFollowsFocus = false,
  }) async {
    field = FocusNode();
    addTearDown(field.dispose);
    final isPadUp = ValueNotifier(isOwnKeyboardUp);
    addTearDown(isPadUp.dispose);
    if (padFollowsFocus) {
      field.addListener(() => isPadUp.value = field.hasFocus);
    }
    form = _FakeFormCubit((
      hasUnsavedChanges: hasUnsavedChanges,
      isSaving: isSaving,
    ));
    addTearDown(form.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider.value(
                  value: form,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isPadUp,
                    builder: (_, isUp, _) =>
                        DiscardLineGuard<_FakeFormCubit, _Form>(
                          hasUnsavedChanges: (state) => state.hasUnsavedChanges,
                          isSaveRunning: (state) => state.isSaving,
                          itemNameOf: (_) => 'Interior paint',
                          isOwnKeyboardUp: isUp,
                          child: Material(
                            key: sheetKey,
                            child: TextField(key: fieldKey, focusNode: field),
                          ),
                        ),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
    field.requestFocus();
    await tester.pump();
  }

  Future<void> tryToClose(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('with the number pad up, the first close only drops focus, '
      'even with nothing typed', (tester) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: true,
      hasUnsavedChanges: false,
    );

    await tryToClose(tester);

    expect(find.byKey(sheetKey), findsOneWidget);
    expect(field.hasFocus, isFalse);
    expect(find.text('Discard this line?'), findsNothing);
  });

  testWidgets('with the number pad up and something typed, the first close '
      'drops focus and does not ask yet', (tester) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: true,
      hasUnsavedChanges: true,
    );

    await tryToClose(tester);

    expect(field.hasFocus, isFalse);
    expect(find.text('Discard this line?'), findsNothing);
  });

  testWidgets('with no keyboard up and nothing typed, closing closes', (
    tester,
  ) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: false,
      hasUnsavedChanges: false,
    );

    await tryToClose(tester);

    expect(find.byKey(sheetKey), findsNothing);
  });

  testWidgets('with no keyboard up and something typed, closing asks', (
    tester,
  ) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: false,
      hasUnsavedChanges: true,
    );

    await tryToClose(tester);

    expect(find.text('Discard this line?'), findsOneWidget);
    expect(find.byKey(sheetKey), findsOneWidget);
  });

  testWidgets('with the number pad up, closing while a save runs drops focus '
      'at once and does not ask when the save ends', (tester) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: true,
      hasUnsavedChanges: true,
      isSaving: true,
    );

    await tryToClose(tester);
    expect(field.hasFocus, isFalse);

    form.finishSave();
    await tester.pumpAndSettle();

    expect(find.text('Discard this line?'), findsNothing);
    expect(find.byKey(sheetKey), findsOneWidget);
  });

  testWidgets('when the pad follows focus, the first close only drops focus '
      'and the second asks', (tester) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: true,
      hasUnsavedChanges: true,
      padFollowsFocus: true,
    );

    await tryToClose(tester);
    expect(field.hasFocus, isFalse);
    expect(find.text('Discard this line?'), findsNothing);

    await tryToClose(tester);
    expect(find.text('Discard this line?'), findsOneWidget);
    expect(find.byKey(sheetKey), findsOneWidget);
  });

  testWidgets('when the pad follows focus and a save runs, the second close '
      'waits for the save, then asks', (tester) async {
    await openGuardedSheet(
      tester,
      isOwnKeyboardUp: true,
      hasUnsavedChanges: true,
      isSaving: true,
      padFollowsFocus: true,
    );

    await tryToClose(tester);
    expect(field.hasFocus, isFalse);
    await tryToClose(tester);
    expect(find.text('Discard this line?'), findsNothing);

    form.finishSave();
    await tester.pumpAndSettle();

    expect(find.text('Discard this line?'), findsOneWidget);
  });
}
