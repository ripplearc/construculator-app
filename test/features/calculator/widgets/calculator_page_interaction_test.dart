import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalculatorPage(),
      ),
    );
  }

  CalculatorBloc blocOf(WidgetTester tester) => BlocProvider.of<CalculatorBloc>(
    tester.element(find.byType(CoreKeyboard)),
  );

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> press(WidgetTester tester, String key) async {
    await tester.tap(find.byKey(ValueKey(key)));
    await tester.pump();
  }

  testWidgets('keyboard taps reach the bloc through the page callbacks', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);

    await press(tester, 'calc_key_Length');
    expect(bloc.state.activeInputLabel, 'Length');
    expect(bloc.state.isTyping, isTrue);

    await press(tester, 'calc_key_two');
    await press(tester, 'calc_key_four');
    expect(bloc.state.currentInputValue, '24');

    await press(tester, 'calc_key_delete');
    expect(bloc.state.currentInputValue, '2');

    await press(tester, 'calc_key_feet');
    expect(bloc.state.currentInputValue, '2 ft');

    await press(tester, 'calc_key_add');
    expect(bloc.state.completedChips, isEmpty);

    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    expect(bloc.state.completedChips, hasLength(1));
    expect(bloc.state.isTyping, isFalse);

    await press(tester, 'calc_key_clearAll');
    expect(bloc.state, equals(CalculatorState.initial()));
  });

  testWidgets('a swipe on the function-key strip selects the next group', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    expect(bloc.state.currentGroupIndex, 0);

    await tester.drag(
      find.byKey(const ValueKey('calc_key_Length')),
      Offset(-CoreKeyboard.groupSwipeThreshold * 3, 0),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(bloc.state.currentGroupIndex, 1);
    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));
    expect(keyboard.currentGroup, equals(keyboard.allGroups[1].name));
  });

  testWidgets('the "View all" sheet selects a group by its header', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);

    await tester.tap(find.text('View all'));
    await settle(tester);
    expect(find.byType(CoreFunctionKeyBottomSheet), findsOneWidget);

    final materialsHeader = find.textContaining('Materials group');
    await tester.scrollUntilVisible(
      materialsHeader,
      CoreSpacing.space10,
      scrollable: find
          .descendant(
            of: find.byType(ReorderableListView),
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 30,
    );
    await tester.ensureVisible(materialsHeader.last);
    await settle(tester);
    await tester.tap(materialsHeader.last);
    await settle(tester);

    expect(find.byType(CoreFunctionKeyBottomSheet), findsNothing);
    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));
    expect(
      keyboard.allGroups[bloc.state.currentGroupIndex].name.id,
      'Materials',
    );
  });

  testWidgets('the "View all" sheet flips the unit system', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final systemBefore = bloc.state.currentUnitSystem;

    await tester.tap(find.text('View all'));
    await settle(tester);
    await tester.tap(find.byType(CoreSwitch));
    await settle(tester);

    expect(bloc.state.currentUnitSystem, isNot(equals(systemBefore)));
  });

  testWidgets('expanding the display area folds the keyboard away', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);

    for (var i = 0; i < 6; i++) {
      await press(tester, 'calc_key_Length');
      await press(tester, 'calc_key_one');
      await tester.tap(find.byKey(CoreResultButton.testKey));
      await tester.pump();
    }
    expect(bloc.state.chipsList, hasLength(6));
    Align keyboardAlign() => tester.widget<Align>(
      find
          .ancestor(of: find.byType(CoreKeyboard), matching: find.byType(Align))
          .first,
    );
    ScrollPhysics? displayPhysics() => tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .physics;
    expect(keyboardAlign().heightFactor, 1.0);
    expect(displayPhysics(), isA<AlwaysScrollableScrollPhysics>());

    await tester.flingFrom(
      tester.getTopLeft(find.byType(CoreDisplayArea)) +
          const Offset(CoreSpacing.space10, CoreSpacing.space10),
      const Offset(0, CoreSpacing.space10 * 5),
      1000,
    );
    await settle(tester);

    expect(displayPhysics(), isA<NeverScrollableScrollPhysics>());
    expect(keyboardAlign().heightFactor, closeTo(0.95, 0.001));
  });

  testWidgets('the display area close control resets the calculator', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;

    await press(tester, 'calc_key_Length');
    await press(tester, 'calc_key_seven');
    expect(bloc.state.currentInputValue, '7');

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();
    expect(bloc.state, equals(CalculatorState.initial()));

    semantics.dispose();
  });
}
