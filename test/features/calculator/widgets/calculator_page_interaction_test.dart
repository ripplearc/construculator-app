import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
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
    expect(bloc.state.labelKeyId, 'Length');
    expect(bloc.state.tape.beingTyped, isNotNull);

    await press(tester, 'calc_key_two');
    await press(tester, 'calc_key_four');
    expect(bloc.state.valueText, '24');

    await press(tester, 'calc_key_delete');
    expect(bloc.state.valueText, '2');

    await press(tester, 'calc_key_feet');
    expect(bloc.state.valueText, '2ft');

    await press(tester, 'calc_key_multiply');
    expect(bloc.state.tape.chips, hasLength(2));

    await press(tester, 'calc_key_three');
    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    expect(bloc.state.tape.chips, hasLength(3));
    expect(bloc.state.valueText, '6ft 0in');
    expect(bloc.state.tape.beingTyped, isNull);

    await press(tester, 'calc_key_divideSymbol');
    expect(bloc.state.refusal, isNotNull);

    await press(tester, 'calc_key_clearAll');
    expect(bloc.state, equals(CalculatorState.initial()));
  });

  testWidgets('÷ reaches the tape as a division, and % presses nothing until '
      'CA-1088', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);

    await press(tester, 'calc_key_eight');
    await press(tester, 'calc_key_divide');
    expect(bloc.state.tape.chips, hasLength(2));

    await press(tester, 'calc_key_two');
    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    expect(bloc.state.valueText, '4');

    final settled = bloc.state;
    await press(tester, 'calc_key_percent');
    expect(bloc.state, equals(settled));
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
      await press(tester, 'calc_key_feet');
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

  testWidgets('the display area close control empties the value being typed '
      'and keeps its key, and with nothing typed it is refused', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;

    await press(tester, 'calc_key_Length');
    await press(tester, 'calc_key_seven');
    expect(bloc.state.valueText, '7');

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();
    expect(bloc.state.labelKeyId, 'Length');
    expect(bloc.state.valueText, '');
    expect(bloc.state.refusal, isNull);

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();
    expect(
      bloc.state.refusal,
      const TapeRefused(TapeRefusal.nothingBeingTyped),
    );
  });

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(CoreKeyboard)))!;

  String equalsFace(WidgetTester tester) =>
      tester.widget<CoreKeyboard>(find.byType(CoreKeyboard)).result.label;

  Future<void> typeRectangle(WidgetTester tester) async {
    for (final key in const [
      'calc_key_Length',
      'calc_key_two',
      'calc_key_two',
      'calc_key_feet',
      'calc_key_Width',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_feet',
      'calc_key_eight',
      'calc_key_inch',
    ]) {
      await press(tester, key);
    }
  }

  testWidgets('the strip names the answers from l10n over their values and '
      'the conversions by their values alone', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);

    expect(find.text(l10n.calculatorStripPlaceholder), findsOneWidget);
    expect(equalsFace(tester), CalculatorLabelFormatter.equalsSign);

    await typeRectangle(tester);

    final strip = tester.widget<CoreSuggestionArea>(
      find.byType(CoreSuggestionArea),
    );
    expect(
      [for (final chip in strip.aiSuggestions!) '${chip.label}: ${chip.value}'],
      [
        '${l10n.calculatorAnswerArea}: 410.67ft²',
        '${l10n.calculatorAnswerDiagonal}: 28.85ft',
        '${l10n.calculatorAnswerPerimeter}: 81.33ft',
      ],
    );
    expect([
      for (final chip in strip.aiSuggestions!) chip.kind,
    ], everyElement(SuggestionKind.deterministic));
    expect(
      [for (final chip in strip.conversionSuggestions!) chip.value],
      ['224in', '5.69m'],
    );
    expect([
      for (final chip in strip.conversionSuggestions!) chip.label,
    ], everyElement(isEmpty));
    expect([
      for (final chip in strip.conversionSuggestions!) chip.kind,
    ], everyElement(SuggestionKind.conversion));
    expect(find.text(l10n.calculatorAnswerArea), findsOneWidget);
    expect(find.text(l10n.calculatorStripPlaceholder), findsNothing);
    expect(equalsFace(tester), l10n.calculatorAnswerArea);
  });

  testWidgets('tapping a strip chip lands its answer on the tape, and the '
      'equals key follows the next leading suggestion', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = l10nOf(tester);
    await typeRectangle(tester);

    await tester.tap(find.byKey(CoreSuggestionArea.chipTestKey(0)));
    await tester.pump();

    expect(bloc.state.labelKeyId, DeterministicRules.areaKey);
    expect(bloc.state.valueText, '410.67ft²');
    expect(find.text(l10n.calculatorAnswerArea), findsWidgets);
    expect(equalsFace(tester), l10n.calculatorAnswerDiagonal);

    await tester.tap(find.byKey(CoreSuggestionArea.conversionChipTestKey(0)));
    await tester.pump();

    expect(bloc.state.valueText, '45.63yd²');
    // A tapped chip keeps its highlight for a second.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a suggestion whose name does not fit keeps the = sign on the '
      'key, and = still lands it', (tester) async {
    // A tablet-wide view: CoreCalculatorChip and the label row do not yet
    // ellipsize a key as long as "Pitch-rise per 12in run" at phone width,
    // which T1a (CA-1092) takes up with the display area.
    await pumpPage(tester, size: const Size(800, 844));
    final bloc = blocOf(tester);
    for (final key in const [
      'calc_key_Rise',
      'calc_key_six',
      'calc_key_feet',
      'calc_key_Run',
      'calc_key_one',
      'calc_key_two',
      'calc_key_feet',
    ]) {
      await press(tester, key);
    }

    expect(bloc.state.equalsKeyId, DeterministicRules.pitchRiseKey);
    expect(equalsFace(tester), CalculatorLabelFormatter.equalsSign);

    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();

    expect(bloc.state.labelKeyId, DeterministicRules.pitchRiseKey);
    expect(bloc.state.valueText, '6in/12in');
  });

  testWidgets('the equals key reads Calc while a chain is pending and Ans '
      'while it continues from a result', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_seven',
      'calc_key_eight',
      'calc_key_multiply',
      'calc_key_five',
    ]) {
      await press(tester, key);
    }
    expect(equalsFace(tester), l10n.calculatorResultCalc);

    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    await press(tester, 'calc_key_multiply');
    await press(tester, 'calc_key_two');

    expect(equalsFace(tester), l10n.calculatorEqualsAns);
  });

  testWidgets('the label row names the reading of a bare number, and the '
      'value row writes it after the number', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Pitch',
      'calc_key_eight',
      'calc_key_decimal',
      'calc_key_four',
      'calc_key_five',
    ]) {
      await press(tester, key);
    }

    final display = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );
    expect(
      display.label,
      '${l10n.calculatorKeyPitch} · ${l10n.calculatorReadingDegrees}',
    );
    expect(display.isTyping, isTrue);
    expect(display.value, '8.45°');
  });

  testWidgets('the label row names the reading of a bare number and the '
      'Read-as pill offers the other one; a tap re-reads the number and the '
      'conversions row folds while the pill shows', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Pitch',
      'calc_key_eight',
      'calc_key_decimal',
      'calc_key_four',
      'calc_key_five',
    ]) {
      await press(tester, key);
    }

    final display = tester.widget<CoreDisplayArea>(
      find.byType(CoreDisplayArea),
    );
    expect(
      display.label,
      '${l10n.calculatorKeyPitch} · ${l10n.calculatorReadingDegrees}',
    );
    expect(display.isTyping, isTrue);
    expect(display.value, '8.45°');
    expect(
      display.dependentKeys.single.label,
      l10n.calculatorPillInputAs('8.45°'),
    );
    expect(display.dependentKeys.single.value, '8.45in/12in');
    expect(display.dependentKeys.single.kind, CoreDependentKeyKind.offer);
    expect(
      display.dependentKeys.single.semanticsHint,
      l10n.calculatorPillReadAsHint,
    );
    expect(
      tester
          .widget<CoreSuggestionArea>(find.byType(CoreSuggestionArea))
          .secondRowHidden,
      isTrue,
    );

    await tester.tap(find.byKey(CoreDisplayArea.dependentKeyTestKey(0)));
    await tester.pump();

    expect(bloc.state.valueText, '8.45in/12in');
    expect(
      tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea)).label,
      '${l10n.calculatorKeyPitch} · ${l10n.calculatorReadingRisePerFoot}',
    );
  });

  testWidgets('a pitch answer carries the Shown as pill, and a tap respells '
      'it under the next reading', (tester) async {
    // A tablet-wide view, as the long-name test above: a pitch result chip
    // does not yet ellipsize at phone width (T1a, CA-1092).
    await pumpPage(tester, size: const Size(800, 844));
    final bloc = blocOf(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Rise',
      'calc_key_six',
      'calc_key_feet',
      'calc_key_Run',
      'calc_key_one',
      'calc_key_two',
      'calc_key_feet',
      'calc_key_Pitch',
    ]) {
      await press(tester, key);
    }

    var display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(display.value, '6in/12in');
    expect(display.dependentKeys.single.label, l10n.calculatorPillShownAs);
    expect(
      display.dependentKeys.single.value,
      l10n.calculatorReadingRisePerFoot,
    );
    expect(display.dependentKeys.single.kind, CoreDependentKeyKind.toggle);

    await tester.tap(find.byKey(CoreDisplayArea.dependentKeyTestKey(0)));
    await tester.pump();

    display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(bloc.state.valueText, '26.57°');
    expect(display.dependentKeys.single.value, l10n.calculatorReadingDegrees);
  });

  testWidgets('a chip with no key is named by its operator, and a closed '
      'bracket by its inside over its value', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_two',
      'calc_key_add',
      'calc_key_paren',
      'calc_key_three',
      'calc_key_multiply',
      'calc_key_four',
    ]) {
      await press(tester, key);
    }
    var display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(display.label, l10n.calculatorOperatorMultiplication);
    expect(display.value, '4');

    await press(tester, 'calc_key_paren');

    display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(display.label, '${l10n.calculatorOperatorAddition} · (3×4)');
    expect(display.isTyping, isFalse);
    expect(display.value, '12');
  });
}
