import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/formatters/calculator_label_formatter.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/features/calculator/testing/fake_trade_stores_repository.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations_en.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';
import '../helpers/calculator_bloc_factory.dart';

void main() {
  setUpAll(loadAppFontsAll);

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    FakeAppRouter? router,
    ThemeData? theme,
    FakeTradeStoresRepository? stores,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalculatorPage(
          router: router ?? FakeAppRouter(),
          calculatorBlocFactory: () => calculatorBlocForTests(stores: stores),
        ),
      ),
    );
  }

  Finder bigValueOf(String text, ThemeData theme) {
    final fontSize = theme
        .extension<AppTypographyExtension>()
        ?.headlineLargeSemiBold
        .fontSize;
    return find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == text &&
          widget.style?.fontSize == fontSize,
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

  testWidgets('the keyboard is read in the app\'s words: the bracket key by '
      'its l10n name and hint (CA-1198)', (tester) async {
    await pumpPage(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;

    final bracket = tester.getSemantics(
      find.byKey(const ValueKey('calc_key_paren')),
    );
    expect(bracket.label, contains(l10n.calculatorBracketKeySemantics));
    expect(bracket.hint, l10n.calculatorBracketKeyHint);
  });

  testWidgets('the keyboard shows the app\'s words, not coreui\'s English: '
      'View all, the sheet title, a group header and the unit switch '
      '(CA-1370)', (tester) async {
    await pumpPage(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    final keyboard = tester.widget<CoreKeyboard>(find.byType(CoreKeyboard));

    expect(keyboard.labels, isNot(same(CoreKeyboardLabels.english)));
    expect(keyboard.semantics, isNot(same(CoreKeyboardSemantics.english)));
    expect(
      (
        keyboard.labels.viewAll,
        keyboard.labels.functionKeys,
        keyboard.labels.groupHeader(l10n.calculatorGroupShapes),
        keyboard.labels.measurementSystem,
        keyboard.labels.imperial,
        keyboard.labels.metric,
      ),
      (
        l10n.calculatorViewAllButton,
        l10n.calculatorFunctionKeysTitle,
        l10n.calculatorGroupHeader(l10n.calculatorGroupShapes),
        l10n.calculatorMeasurementSystem,
        l10n.calculatorUnitSystemImperial,
        l10n.calculatorUnitSystemMetric,
      ),
    );

    await tester.tap(find.text(l10n.calculatorViewAllButton));
    await settle(tester);
    expect(find.text(l10n.calculatorFunctionKeysTitle), findsOneWidget);
    expect(find.text(l10n.calculatorMeasurementSystem), findsOneWidget);
  });

  testWidgets('÷ reaches the tape as a division, and % after a result is '
      'refused with a red Alert (CA-1376; rule 4.12)', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;

    await press(tester, 'calc_key_eight');
    await press(tester, 'calc_key_divide');
    expect(bloc.state.tape.chips, hasLength(2));

    await press(tester, 'calc_key_two');
    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    expect(bloc.state.valueText, '4');

    final tape = bloc.state.tape;
    await press(tester, 'calc_key_percent');
    await settle(tester);
    expect(bloc.state.tape, tape);
    expect(
      find.text(l10n.calculatorToastPercentNeedsAnOperatorTitle),
      findsOneWidget,
    );
  });

  testWidgets('the % key marks a percent on the tape, "+10%", the strip says '
      'what it adds, and = lands the total (CA-1376; decision tree row '
      '386)', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_one',
      'calc_key_zero',
      'calc_key_zero',
      'calc_key_zero',
      'calc_key_add',
      'calc_key_five',
      'calc_key_zero',
      'calc_key_zero',
      'calc_key_add',
      'calc_key_one',
      'calc_key_zero',
      'calc_key_percent',
    ]) {
      await press(tester, key);
    }

    expect(
      [for (final chip in bloc.state.chipsList) chip.value],
      ['1000', '+500', '+10%'],
    );
    expect(
      find.text(
        l10n.calculatorNotePercentAddsOfTheTotal('10%', '1,500', '150'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(CoreResultButton.testKey));
    await tester.pump();
    expect(bloc.state.valueText, '1,650');
    expect(
      find.text(
        l10n.calculatorNotePercentAddsOfTheTotal('10%', '1,500', '150'),
      ),
      findsNothing,
      reason: 'the tip closes on the next key',
    );
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

    await tester.tap(find.text(AppLocalizationsEn().calculatorViewAllButton));
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

    await tester.tap(find.text(AppLocalizationsEn().calculatorViewAllButton));
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
      'and keeps its key, then clears the waiting chip, and with nothing in '
      'progress it leaves the calculator (Section 1.1)', (tester) async {
    final router = FakeAppRouter();
    await pumpPage(tester, router: router);
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
    expect(router.popCalls, 0);

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();
    expect(bloc.state.labelKeyId, isNull);
    expect(bloc.state.tape.isEmpty, isTrue);
    expect(bloc.state.refusal, isNull);
    expect(bloc.state.closesCalculator, isFalse);
    expect(router.popCalls, 0);

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();
    expect(bloc.state.refusal, isNull);
    expect(bloc.state.closesCalculator, isTrue);
    expect(router.popCalls, 1);
  });

  testWidgets('✕ on the empty tape leaves the calculator at once, and no '
      'toast is asked for', (tester) async {
    final router = FakeAppRouter();
    await pumpPage(tester, router: router);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;

    await tester.tap(find.bySemanticsLabel(l10n.closeButton));
    await tester.pump();

    expect(router.popCalls, 1);
    expect(router.navigationHistory, isEmpty);
    expect(blocOf(tester).state.refusal, isNull);

    blocOf(tester).add(const CalculatorGroupSelected(1));
    await tester.pump();

    expect(blocOf(tester).state.closesCalculator, isTrue);
    expect(router.popCalls, 1);
  });

  testWidgets('a bracket is one chip on the tape, in its open face while the '
      'keypad types inside it and in its closed face once it has its ")", '
      'with the chips before it dimmed only while it is open', (tester) async {
    await pumpPage(tester);

    await press(tester, 'calc_key_two');
    await press(tester, 'calc_key_add');
    await press(tester, 'calc_key_paren');
    await press(tester, 'calc_key_three');

    CoreCalculatorChip chipOf(CoreCalculatorChipType type) => tester.widget(
      find.byWidgetPredicate(
        (widget) => widget is CoreCalculatorChip && widget.type == type,
      ),
    );
    final open = chipOf(CoreCalculatorChipType.bracketOpen);
    expect(open.displayedValue, '(3');
    expect(open.factor, CoreIcons.addOperator);
    expect(chipOf(CoreCalculatorChipType.editable).inert, isTrue);

    await press(tester, 'calc_key_paren');

    final closed = chipOf(CoreCalculatorChipType.bracketClosed);
    expect(closed.displayedValue, '(3)');
    expect(closed.factor, CoreIcons.addOperator);
    expect(chipOf(CoreCalculatorChipType.editable).inert, isFalse);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CoreCalculatorChip &&
            widget.type == CoreCalculatorChipType.bracketOpen,
      ),
      findsNothing,
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

  testWidgets('after Area is accepted the strip leads with the sheet counts '
      'as predictive chips, each with its size from l10n, and tapping one '
      'lands Number of sheets (S2a, CA-1090; rule 4.4 rung 2a; row 218)', (
    tester,
  ) async {
    // A tablet-wide view: with the test font's wider glyphs a sheet-count
    // chip does not fit the collapsed row at phone width and the strip hides
    // it behind "+5"; with the app's fonts it fits, ellipsized, as the
    // detail-panel golden shows.
    await pumpPage(tester, size: const Size(800, 844));
    final l10n = l10nOf(tester);
    await typeRectangle(tester);
    await tester.tap(find.byKey(CoreResultButton.testKey));
    // the store's answer follows the landed Area a frame later, and the
    // chips it brings slide in before they can be tapped
    await tester.pump();
    await tester.pump();
    await tester.pump(CoreSuggestionArea.animationDuration);
    await tester.pump();

    final strip = tester.widget<CoreSuggestionArea>(
      find.byType(CoreSuggestionArea),
    );
    expect(
      [for (final chip in strip.aiSuggestions!) '${chip.label}: ${chip.value}'],
      [
        '${l10n.calculatorOfferDrywall}: '
            '${l10n.calculatorOfferSheetCount('12.83', '48in x 96in')}',
        '${l10n.calculatorOfferDrywall}: '
            '${l10n.calculatorOfferSheetCount('11.41', '48in x 108in')}',
        '${l10n.calculatorOfferDrywall}: '
            '${l10n.calculatorOfferSheetCount('10.27', '48in x 120in')}',
        '${l10n.calculatorAnswerDiagonal}: 28.85ft',
        '${l10n.calculatorAnswerPerimeter}: 81.33ft',
      ],
    );
    expect(
      [for (final chip in strip.aiSuggestions!.take(3)) chip.kind],
      [
        SuggestionKind.predictive,
        SuggestionKind.predictive,
        SuggestionKind.predictive,
      ],
    );
    expect(equalsFace(tester), CalculatorLabelFormatter.equalsSign);

    await tester.tap(find.byKey(CoreSuggestionArea.chipTestKey(0)));
    await tester.pump();
    await tester.pump();

    final bloc = blocOf(tester);
    expect(bloc.state.refusal, isNull);
    expect(
      [for (final chip in bloc.state.chipsList) '${chip.label}${chip.value}'],
      ['Length22ft', 'Width18ft 8in', 'Area410.67ft²', 'Number of sheets12.83'],
    );
    expect(bloc.state.labelKeyId, Trade.drywall.resultKey);
    expect(bloc.state.valueText, '12.83');
    expect(find.text(l10n.calculatorAnswerNumberOfSheets), findsWidgets);
    final after = tester.widget<CoreSuggestionArea>(
      find.byType(CoreSuggestionArea),
    );
    expect(
      [for (final chip in after.aiSuggestions!.take(2)) chip.value],
      [
        l10n.calculatorOfferSheetCount('11.41', '48in x 108in'),
        l10n.calculatorOfferSheetCount('10.27', '48in x 120in'),
      ],
    );
    // A tapped chip keeps its highlight for a second.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tapping a strip chip lands its answer on the tape, and the '
      'equals key reads = while the strip still offers the next answer, '
      'since = after a result lands nothing', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = l10nOf(tester);
    await typeRectangle(tester);

    await tester.tap(find.byKey(CoreSuggestionArea.chipTestKey(0)));
    await tester.pump();

    expect(bloc.state.labelKeyId, DeterministicRules.areaKey);
    expect(bloc.state.valueText, '410.67ft²');
    expect(find.text(l10n.calculatorAnswerArea), findsWidgets);
    // the sheet counts lead after an accepted Area (S2a); Diagonal follows
    expect(bloc.state.suggestions.first.key, Trade.drywall.offerKey);
    expect(bloc.state.suggestions[3].key, DeterministicRules.diagonalKey);
    expect(bloc.state.equalsKeyId, isNull);
    expect(equalsFace(tester), CalculatorLabelFormatter.equalsSign);

    await tester.tap(find.byKey(CoreSuggestionArea.conversionChipTestKey(0)));
    await tester.pump();

    expect(bloc.state.valueText, '45.63yd²');
    // A tapped chip keeps its highlight for a second.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a suggestion whose name does not fit keeps the = sign on the '
      'key, and = still lands it', (tester) async {
    // A tablet-wide view: CoreCalculatorChip and the label row do not yet
    // ellipsize a key as long as "Pitch-rise per 12in run" at phone width.
    // TODO: [CA-1405] Run this test at 390 px once CoreUI cuts the label.
    // https://ripplearc.youtrack.cloud/issue/CA-1405
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

  testWidgets('the label reads Value over a finished bare value, as over '
      'one still typed (term 2.6)', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    await press(tester, 'calc_key_one');
    await press(tester, 'calc_key_two');
    var display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(display.label, l10n.calculatorLabelValue);
    expect(display.isTyping, isTrue);

    await press(tester, 'calc_key_feet');

    display = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(display.label, l10n.calculatorLabelValue);
    expect(display.isTyping, isFalse);
    expect(display.value, '12ft');
    expect(find.text(l10n.calculatorLabelValue), findsOneWidget);
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
    final reRead = tester.widget<CoreDisplayArea>(find.byType(CoreDisplayArea));
    expect(
      reRead.label,
      '${l10n.calculatorKeyPitch} · ${l10n.calculatorReadingRisePerFoot}',
    );
    expect(
      reRead.dependentKeys.single.label,
      l10n.calculatorPillInputAs('8.45in/12in'),
    );
    expect(
      reRead.dependentKeys.single.value,
      '8.45°',
      reason: 'the way back, never D:M:S (decision tree row 260)',
    );

    await tester.tap(find.byKey(CoreDisplayArea.dependentKeyTestKey(0)));
    await tester.pump();

    expect(bloc.state.valueText, '8.45°', reason: 'the pill toggles (S86)');
  });

  testWidgets('= while the pitch note holds the strip shows a red Alert in '
      'the words of the note, and the tape stays (decision tree row 375)', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Pitch',
      'calc_key_nine',
      'calc_key_five',
      'calc_key_Run',
      'calc_key_one',
      'calc_key_zero',
      'calc_key_feet',
    ]) {
      await press(tester, key);
    }
    final before = bloc.state.tape;

    await tester.tap(find.byKey(CoreResultButton.testKey));
    await settle(tester);

    expect(
      find.text(l10n.calculatorToastPitchUnderRightAngleTitle),
      findsOneWidget,
    );
    expect(find.text(l10n.calculatorToastEditThePitchChipBody), findsOneWidget);
    expect(bloc.state.tape, before);
    expect(
      find.text(l10n.calculatorNotePitchUnderRightAngle),
      findsOneWidget,
      reason: 'the note stays while its cause stays',
    );
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

  testWidgets('a strip note stays on the screen while a length is named '
      'after the pitch, because it empties the conversions row too '
      '(Sections 1.8 and 5.4)', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Pitch',
      'calc_key_nine',
      'calc_key_five',
      'calc_key_Run',
      'calc_key_one',
      'calc_key_zero',
      'calc_key_feet',
    ]) {
      await press(tester, key);
    }

    final strip = tester.widget<CoreSuggestionArea>(
      find.byType(CoreSuggestionArea),
    );
    expect(strip.aiSuggestions, isEmpty);
    expect(strip.conversionSuggestions, isEmpty);
    expect(find.text(l10n.calculatorNotePitchUnderRightAngle), findsOneWidget);
    expect(find.text('120in'), findsNothing);
  });

  testWidgets('a strip note takes the whole strip, in its own slot: no '
      'suggestion chip and no placeholder while it shows, and both return '
      'when it clears (CA-1094, acceptance criterion 3)', (tester) async {
    await pumpPage(tester);
    final l10n = l10nOf(tester);
    for (final key in const [
      'calc_key_Pitch',
      'calc_key_nine',
      'calc_key_five',
    ]) {
      await press(tester, key);
    }

    expect(find.text(l10n.calculatorNotePitchUnderRightAngle), findsOneWidget);
    expect(find.byKey(CoreSuggestionArea.chipTestKey(0)), findsNothing);
    expect(find.text(l10n.calculatorStripPlaceholder), findsNothing);

    await press(tester, 'calc_key_clearAll');

    expect(find.text(l10n.calculatorNotePitchUnderRightAngle), findsNothing);
    expect(find.text(l10n.calculatorStripPlaceholder), findsOneWidget);

    for (final key in const ['calc_key_Slope', 'calc_key_seven']) {
      await press(tester, key);
    }
    expect(
      find.byKey(CoreSuggestionArea.chipTestKey(0)),
      findsOneWidget,
      reason: 'the suggestions come back once no note holds the strip',
    );
  });

  testWidgets(
    'a swipe on the function-key strip moves to the next group and back, '
    'through the bloc (Section 1.3)',
    (tester) async {
      await pumpPage(tester);
      final bloc = blocOf(tester);

      await tester.drag(
        find.byKey(const ValueKey('calc_key_Width')),
        const Offset(-120, 0),
      );
      await settle(tester);
      expect(bloc.state.currentGroupIndex, 1);
      expect(
        tester.widget<CoreKeyboard>(find.byType(CoreKeyboard)).currentGroup.id,
        CalculatorGroupId.shapes,
      );

      await tester.drag(
        find.byKey(const ValueKey('calc_key_Diameter')),
        const Offset(120, 0),
      );
      await settle(tester);
      expect(bloc.state.currentGroupIndex, 0);
    },
  );

  testWidgets('a new locale hands the keyboard a new list of groups, so the '
      'words follow the language even while the order stands (T1b F1)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    Future<void> pumpIn(Locale locale) => tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: locale,
            child: CalculatorPage(
              router: FakeAppRouter(),
              calculatorBlocFactory: calculatorBlocForTests,
            ),
          ),
        ),
      ),
    );
    List<FunctionGroup> groups() =>
        tester.widget<CoreKeyboard>(find.byType(CoreKeyboard)).allGroups;

    await pumpIn(const Locale('en'));
    final before = groups();
    await pumpIn(const Locale('en'));
    expect(
      identical(groups(), before),
      isTrue,
      reason: 'the same locale keeps the list the sheet was handed',
    );
    await pumpIn(const Locale('en', 'US'));
    expect(
      identical(groups(), before),
      isFalse,
      reason: 'a new locale rebuilds the groups, so the list is new',
    );
    expect(
      [for (final group in groups()) group.name.id],
      [for (final group in before) group.name.id],
    );
  });

  testWidgets('every function key of the five groups sends its id to the tape '
      '(Section 3)', (tester) async {
    // Wider than a phone: CoreUI's label row overflows at 390 px under a
    // trig chip's long label (CA-1405), and an overflow fails the test.
    await pumpPage(tester, size: const Size(600, 844));
    final bloc = blocOf(tester);
    final groups = tester
        .widget<CoreKeyboard>(find.byType(CoreKeyboard))
        .allGroups;
    expect(groups, hasLength(5));

    for (final (index, group) in groups.indexed) {
      bloc.add(CalculatorGroupSelected(index));
      await settle(tester);
      for (final key in group.keys) {
        bloc.add(const CalculatorResetRequested());
        await tester.pump();
        await press(tester, 'calc_key_${key.id}');
        final state = bloc.state;
        // A named chip opens (a trig key names it by its function, Sine
        // for SIN), or the tape says why it refused the key: either way the
        // key reached the tape, where a reset had left nothing.
        expect(
          state.labelKeyId != null || state.refusal != null,
          isTrue,
          reason: '${key.id} of ${group.name.id} did not reach the tape',
        );
      }
    }
  });

  testWidgets('a tap on an input chip reopens it, the result after it is '
      'drawn dashed, and a second tap seals it again (rule 4.8)', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    for (final key in const [
      'calc_key_Length',
      'calc_key_two',
      'calc_key_two',
      'calc_key_feet',
      'calc_key_Width',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_feet',
    ]) {
      await press(tester, key);
    }
    await settle(tester);
    await tester.tap(find.byKey(CoreSuggestionArea.chipTestKey(0)));
    await settle(tester);
    expect(bloc.state.labelKeyId, 'Area');

    CoreCalculatorChipType faceOf(int index) => tester
        .widget<CoreCalculatorChip>(find.byKey(ValueKey('calc_chip_$index')))
        .type;
    final length = find.byKey(const ValueKey('calc_chip_0'));
    await tester.tap(length);
    await settle(tester);

    expect(bloc.state.tape.editing!.index, 0);
    expect(faceOf(0), CoreCalculatorChipType.active);
    expect(faceOf(2), CoreCalculatorChipType.dashed);
    expect(bloc.state.valueText, '22ft');

    await tester.tap(length);
    await settle(tester);

    expect(bloc.state.tape.editing, isNull);
    expect(faceOf(0), CoreCalculatorChipType.editable);
    expect(faceOf(2), CoreCalculatorChipType.result);
  });

  testWidgets('a key that would leave the chip being typed or edited '
      'incomplete shows the "Finish this value first" Alert with the number '
      '(Section 5.5)', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_Length',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_Width',
    ]) {
      await press(tester, key);
    }
    await settle(tester);

    expect(bloc.state.toast, const CalculatorFinishValueToast(value: '18'));
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsOneWidget);
    expect(
      find.text(l10n.calculatorToastFinishValueBody('18')),
      findsOneWidget,
    );
  });

  testWidgets('the red Alert sits above the key sheet, so the key it asks '
      'for still works and closes it, and no timer closes it (term 2.21; '
      'Section 5)', (tester) async {
    await pumpPage(tester);
    final displayBefore = tester.getRect(find.byType(CoreDisplayArea));
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_Length',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_Width',
    ]) {
      await press(tester, key);
    }
    await settle(tester);
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsOneWidget);
    final alert = tester.getRect(
      find.byKey(const ValueKey('calculator_alert')),
    );
    final keyboard = tester.getRect(find.byType(CoreKeyboard));
    expect(alert.bottom, lessThanOrEqualTo(keyboard.top));
    final box = tester.getRect(find.byType(Toast));
    expect(
      keyboard.top - box.bottom,
      CoreSpacing.space1,
      reason: 'the box ends 4 px above the top edge of the key sheet',
    );
    expect(
      tester.getRect(find.byType(CoreDisplayArea)),
      displayBefore,
      reason:
          'on a tall phone the value is clear of the Alert, so the '
          'display does not scroll',
    );

    await tester.pump(const Duration(seconds: 10));
    expect(
      find.text(l10n.calculatorToastFinishValueTitle),
      findsOneWidget,
      reason: 'only its ✕ or the next key closes it',
    );

    await press(tester, 'calc_key_feet');
    await settle(tester);
    expect(bloc.state.valueText, '18ft');
    expect(bloc.state.toast, isNull);
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsNothing);
  });

  for (final size in const [Size(375, 667), Size(360, 640)]) {
    testWidgets(
      'on a ${size.width.toInt()} × ${size.height.toInt()} phone the red '
      'Alert is drawn over the display area: the key sheet keeps its place, '
      'nothing overflows, and the display scrolls so the value the Alert '
      'talks about sits above it, then scrolls back when the Alert closes '
      '(B2; term 2.21; rule 4.12)',
      (tester) async {
        final theme = createTestTheme();
        await pumpPage(tester, size: size, theme: theme);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CoreKeyboard)),
        )!;
        final bigValue = bigValueOf('18', theme);
        final displayViewport = find.ancestor(
          of: find.byType(CoreDisplayArea),
          matching: find.byType(SingleChildScrollView),
        );
        final keyboardBefore = tester.getRect(find.byType(CoreKeyboard));
        final displayBefore = tester.getRect(find.byType(CoreDisplayArea));
        final viewportBefore = tester.getRect(displayViewport);
        for (final key in const [
          'calc_key_Length',
          'calc_key_one',
          'calc_key_eight',
          'calc_key_Width',
        ]) {
          await press(tester, key);
        }
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'no overflow');
        expect(find.text(l10n.calculatorToastFinishValueTitle), findsOneWidget);
        final keyboard = tester.getRect(find.byType(CoreKeyboard));
        expect(keyboard.top, keyboardBefore.top, reason: 'the keys stay put');
        expect(
          tester.getRect(find.byKey(const ValueKey('calc_key_zero'))).bottom,
          lessThanOrEqualTo(size.height),
          reason: 'the bottom key row stays inside the screen',
        );
        final box = tester.getRect(find.byType(Toast));
        expect(keyboard.top - box.bottom, CoreSpacing.space1);
        expect(
          tester.getRect(displayViewport),
          viewportBefore,
          reason: 'the display keeps its place and height under the Alert',
        );
        final value = tester.getRect(bigValue);
        expect(
          value.overlaps(box),
          isFalse,
          reason: 'the Alert does not cover the value: $value under $box',
        );
        expect(value.bottom, lessThanOrEqualTo(box.top));
        expect(
          value.center.dy,
          greaterThan(viewportBefore.top),
          reason: 'the value is still on the screen',
        );

        await press(tester, 'calc_key_feet');
        await settle(tester);
        expect(find.byType(Toast), findsNothing);
        expect(
          tester.getRect(find.byType(CoreDisplayArea)),
          displayBefore,
          reason: 'the display is back where it was once the Alert closes',
        );
      },
    );
  }

  testWidgets('a refused key is announced to a screen reader every time it '
      'is raised, and a state that merely still holds it, a group swipe, '
      'announces nothing (rule 4.12)', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        if (message case {
          'type': 'announce',
          'data': {'message': final String text},
        }) {
          announced.add(text);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    await pumpPage(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_Length',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_Width',
      'calc_key_Width',
    ]) {
      await press(tester, key);
    }
    await settle(tester);

    expect(announced, [
      l10n.calculatorToastFinishValueBody('18'),
      l10n.calculatorToastFinishValueBody('18'),
    ]);

    blocOf(tester).add(const CalculatorGroupSelected(2));
    await settle(tester);

    expect(blocOf(tester).state.toast, isNotNull);
    expect(announced, hasLength(2));
  });

  testWidgets('the same guard raised twice shows its toast twice: a key '
      'refused the same way is never silently dead (rule 4.12)', (
    tester,
  ) async {
    await pumpPage(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_Length',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_Width',
    ]) {
      await press(tester, key);
    }
    await settle(tester);
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsOneWidget);

    await tester.tap(find.byKey(const Key('toast_close_button')));
    await settle(tester);
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsNothing);

    await press(tester, 'calc_key_Width');
    await settle(tester);

    expect(find.text(l10n.calculatorToastFinishValueTitle), findsOneWidget);
  });

  testWidgets('a state that merely still holds the toast does not show it '
      'again: swiping to another group after the guard shows nothing', (
    tester,
  ) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_Length',
      'calc_key_one',
      'calc_key_eight',
      'calc_key_Width',
    ]) {
      await press(tester, key);
    }
    await settle(tester);
    await tester.tap(find.byKey(const Key('toast_close_button')));
    await settle(tester);
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsNothing);

    bloc.add(const CalculatorGroupSelected(2));
    await settle(tester);

    expect(bloc.state.toast, const CalculatorFinishValueToast(value: '18'));
    expect(find.text(l10n.calculatorToastFinishValueTitle), findsNothing);
  });

  testWidgets('a tap on a closed bracket reopens it with the "Editing this '
      'group" message, the other chips wait, and the answer reads a dash '
      '(Section 7, walkthrough 12.8)', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_two',
      'calc_key_add',
      'calc_key_paren',
      'calc_key_three',
      'calc_key_multiply',
      'calc_key_four',
      'calc_key_paren',
      'calc_key_multiply',
      'calc_key_five',
    ]) {
      await press(tester, key);
    }
    await tester.tap(find.byKey(CoreResultButton.testKey));
    await settle(tester);
    expect(bloc.state.valueText, '70');

    CoreCalculatorChip chipAt(int index) => tester.widget<CoreCalculatorChip>(
      find.byKey(ValueKey('calc_chip_$index')),
    );
    final bracket = find.byKey(const ValueKey('calc_chip_1'));
    expect(chipAt(1).type, CoreCalculatorChipType.bracketClosed);
    await tester.tap(bracket);
    await settle(tester);

    expect(bloc.state.tape.openBracketIndex, 1);
    expect(find.text(l10n.calculatorToastEditingGroup), findsOneWidget);
    expect(chipAt(1).type, CoreCalculatorChipType.bracketOpen);
    expect(chipAt(1).inert, isFalse);
    expect(chipAt(3).value, '—');
    expect(chipAt(3).inert, isTrue);

    await press(tester, 'calc_key_paren');
    await settle(tester);
    expect(bloc.state.tape.openBracket, isNull);
    expect(chipAt(3).value, '70');
  });

  testWidgets('"Editing this group" has no timer: it stays until its Close '
      'action or the next key, and it closes with the bracket (Section 5.6; '
      'nit 2)', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(CoreKeyboard)),
    )!;
    for (final key in const [
      'calc_key_two',
      'calc_key_add',
      'calc_key_paren',
      'calc_key_three',
      'calc_key_paren',
    ]) {
      await press(tester, key);
    }
    final bracket = find.byKey(const ValueKey('calc_chip_1'));
    await tester.tap(bracket);
    await settle(tester);
    expect(find.text(l10n.calculatorToastEditingGroup), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.text(l10n.calculatorToastEditingGroup), findsOneWidget);

    await tester.tap(find.byKey(const Key('toast_action_button')));
    await settle(tester);
    expect(find.text(l10n.calculatorToastEditingGroup), findsNothing);
    expect(bloc.state.tape.openBracketIndex, 1);

    await tester.tap(bracket);
    await settle(tester);
    expect(bloc.state.tape.openBracket, isNull);
    await tester.tap(bracket);
    await settle(tester);
    expect(find.text(l10n.calculatorToastEditingGroup), findsOneWidget);
    await press(tester, 'calc_key_paren');
    await settle(tester);
    expect(find.text(l10n.calculatorToastEditingGroup), findsNothing);
  });

  testWidgets('a tap on the reopened bracket itself closes it, as the '
      'bracket key does, and the answer after it comes back', (tester) async {
    await pumpPage(tester);
    final bloc = blocOf(tester);
    for (final key in const [
      'calc_key_two',
      'calc_key_add',
      'calc_key_paren',
      'calc_key_three',
      'calc_key_paren',
    ]) {
      await press(tester, key);
    }
    await tester.tap(find.byKey(CoreResultButton.testKey));
    await settle(tester);
    expect(bloc.state.valueText, '5');

    final bracket = find.byKey(const ValueKey('calc_chip_1'));
    await tester.tap(bracket);
    await settle(tester);
    expect(bloc.state.tape.openBracketIndex, 1);

    await tester.tap(bracket);
    await settle(tester);

    expect(bloc.state.tape.openBracket, isNull);
    expect(
      tester
          .widget<CoreCalculatorChip>(find.byKey(const ValueKey('calc_chip_2')))
          .value,
      '5',
    );
  });

  group('T2a 1/2: the keypad folds to show the detail panel (Section 1.4, '
      'term 2.17)', () {
    const panel = Key('calculator_detail_panel');
    const firstDigit = ValueKey('calc_key_one');

    Finder handle() => find.bySemanticsLabel(
      AppLocalizationsEn().calculatorKeyboardHandleSemantics,
    );

    Finder inPanel(String text) =>
        find.descendant(of: find.byKey(panel), matching: find.text(text));

    Future<void> acceptAreaOf20ftBy9ft(WidgetTester tester) async {
      for (final key in const [
        'calc_key_Length',
        'calc_key_two',
        'calc_key_zero',
        'calc_key_feet',
        'calc_key_Height',
        'calc_key_nine',
        'calc_key_feet',
      ]) {
        await press(tester, key);
      }
      await tester.tap(find.byKey(CoreResultButton.testKey));
      await tester.pump();
    }

    testWidgets('a tap on the handle folds the keypad and shows the tiles '
        'of what Area 180ft² left unasked: Diagonal 21.93ft and Perimeter '
        '58ft (walkthrough 11.3, decision tree row 224)', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await acceptAreaOf20ftBy9ft(tester);
      expect(find.byKey(panel), findsNothing);
      expect(find.text(l10n.calculatorDetailDimensionsTitle), findsNothing);

      await tester.tap(handle());
      await settle(tester);

      expect(find.text(l10n.calculatorDetailDimensionsTitle), findsOneWidget);
      expect(find.text(l10n.calculatorDetailExpandButton), findsOneWidget);
      expect(inPanel(l10n.calculatorAnswerDiagonal), findsOneWidget);
      expect(inPanel('21.93ft'), findsOneWidget);
      expect(inPanel(l10n.calculatorAnswerPerimeter), findsOneWidget);
      expect(inPanel('58ft'), findsOneWidget);
      expect(inPanel(l10n.calculatorAnswerArea), findsNothing);
      expect(
        inPanel(CoreGeometryArea.defaultAttachmentsTitleLabel),
        findsNothing,
        reason: 'the detail panel of Section 1.4 has no attachments',
      );
      expect(find.byKey(firstDigit).hitTestable(), findsNothing);
    });

    testWidgets('under the fold the strip sits right below the display and '
        'the panel right below the strip', (tester) async {
      await pumpPage(tester);
      await acceptAreaOf20ftBy9ft(tester);
      await tester.tap(handle());
      await settle(tester);

      final display = tester.getRect(find.byType(CoreDisplayArea));
      final strip = tester.getRect(find.byType(CoreSuggestionArea));
      final detail = tester.getRect(find.byKey(panel));
      expect(strip.top, display.bottom);
      expect(detail.top, strip.bottom);
      expect(
        detail.bottom,
        tester.getRect(find.byType(CoreKeyboard)).top,
        reason: 'the panel takes the room left above the folded keys, no more',
      );
    });

    testWidgets('folding and unfolding leave the tape, the label and the '
        'value as they were, and unfolding brings the keys back (decision '
        'tree row 227, case 1)', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await acceptAreaOf20ftBy9ft(tester);
      final bloc = blocOf(tester);
      final accepted = bloc.state;

      await tester.tap(handle());
      await settle(tester);
      expect(bloc.state, equals(accepted));
      expect(find.text(l10n.calculatorAnswerArea), findsWidgets);
      expect(find.text('180ft²'), findsWidgets);

      await tester.tap(handle());
      await settle(tester);
      expect(bloc.state, equals(accepted));
      expect(find.byKey(panel), findsNothing);
      expect(find.text(l10n.calculatorDetailDimensionsTitle), findsNothing);

      await press(tester, 'calc_key_one');
      expect(bloc.state.valueText, '1');
    });

    testWidgets('a drag down on the handle folds the keypad and a drag up '
        'unfolds it', (tester) async {
      await pumpPage(tester);
      await acceptAreaOf20ftBy9ft(tester);

      await tester.fling(handle(), const Offset(0, 200), 1000);
      await settle(tester);
      expect(find.byKey(panel), findsOneWidget);
      expect(find.byKey(firstDigit).hitTestable(), findsNothing);

      await tester.fling(handle(), const Offset(0, -200), 1000);
      await settle(tester);
      expect(find.byKey(panel), findsNothing);
      expect(find.byKey(firstDigit).hitTestable(), findsOneWidget);
    });

    testWidgets('a value still being typed keeps its label and value under '
        'the fold, and its shape gives the tiles (decision tree row 227, '
        'case 2: Radius 6ft)', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      final bloc = blocOf(tester)
        ..add(const CalculatorKeySelected('Radius'))
        ..add(const CalculatorDigitPressed('6'))
        ..add(const CalculatorUnitSelected(Unit.foot));
      await tester.pump();
      final typed = bloc.state;

      await tester.tap(handle());
      await settle(tester);

      expect(bloc.state, equals(typed));
      expect(bloc.state.labelKeyId, 'Radius');
      expect(bloc.state.valueText, '6ft');
      expect(inPanel(l10n.calculatorKeyDiameter), findsOneWidget);
      expect(inPanel('12ft'), findsOneWidget);
    });

    testWidgets('the tiles follow the tape while the keypad stays folded: '
        'an answer accepted from the strip leaves them', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await acceptAreaOf20ftBy9ft(tester);
      await tester.tap(handle());
      await settle(tester);
      expect(inPanel(l10n.calculatorAnswerDiagonal), findsOneWidget);

      final bloc = blocOf(tester);
      bloc.add(
        CalculatorSuggestionAccepted(
          bloc.state.suggestions.firstWhere(
            (chip) => chip.key == DeterministicRules.diagonalKey,
          ),
        ),
      );
      await settle(tester);

      expect(bloc.state.labelKeyId, DeterministicRules.diagonalKey);
      expect(inPanel(l10n.calculatorAnswerDiagonal), findsNothing);
      expect(inPanel(l10n.calculatorAnswerPerimeter), findsOneWidget);
    });

    testWidgets('a tape with nothing to work out folds to no panel', (
      tester,
    ) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await press(tester, 'calc_key_one');
      await press(tester, 'calc_key_two');

      await tester.tap(handle());
      await settle(tester);

      expect(find.byKey(firstDigit).hitTestable(), findsNothing);
      expect(find.byKey(panel), findsNothing);
      expect(find.text(l10n.calculatorDetailDimensionsTitle), findsNothing);
    });

    testWidgets('while the display area is pulled open the panel gives its '
        'room back, and it returns when the display closes', (tester) async {
      await pumpPage(tester);
      for (final key in const [
        'calc_key_Length',
        'calc_key_two',
        'calc_key_zero',
        'calc_key_feet',
        'calc_key_Height',
        'calc_key_nine',
        'calc_key_feet',
        'calc_key_add',
        'calc_key_one',
        'calc_key_add',
        'calc_key_one',
        'calc_key_add',
        'calc_key_one',
        'calc_key_add',
        'calc_key_one',
      ]) {
        await press(tester, key);
      }
      await tester.tap(handle());
      await settle(tester);
      expect(find.byKey(panel), findsOneWidget);

      await tester.fling(
        find.byType(CoreDisplayArea),
        const Offset(0, 100),
        1000,
      );
      await settle(tester);
      expect(find.byKey(panel), findsNothing);

      await tester.fling(
        find.byType(CoreDisplayArea),
        const Offset(0, -100),
        1000,
      );
      await settle(tester);
      expect(find.byKey(panel), findsOneWidget);
    });

    testWidgets('the tiles open on Expand and close on Collapse, both '
        'named from l10n', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await acceptAreaOf20ftBy9ft(tester);
      await tester.tap(handle());
      await settle(tester);
      expect(find.text(l10n.calculatorDetailExpandButton), findsOneWidget);
      expect(find.text(l10n.calculatorDetailCollapseButton), findsNothing);

      await tester.tap(find.text(l10n.calculatorDetailExpandButton));
      await settle(tester);
      expect(find.text(l10n.calculatorDetailExpandButton), findsNothing);
      expect(find.text(l10n.calculatorDetailCollapseButton), findsOneWidget);

      await tester.tap(find.text(l10n.calculatorDetailCollapseButton));
      await settle(tester);
      expect(find.text(l10n.calculatorDetailExpandButton), findsOneWidget);
    });
  });

  group('T2a 2/3: the sheet table of the detail panel (Section 1.4, '
      '"sheet sizes with the count for each")', () {
    const panel = Key('calculator_detail_panel');
    const sheetTableId = 'sheet-quantities';

    Finder handle() => find.bySemanticsLabel(
      AppLocalizationsEn().calculatorKeyboardHandleSemantics,
    );

    Finder inPanel(String text) =>
        find.descendant(of: find.byKey(panel), matching: find.text(text));

    Future<void> typeAndFold(WidgetTester tester, List<String> keys) async {
      for (final key in keys) {
        await press(tester, key);
      }
      await settle(tester);
      await tester.tap(handle());
      await settle(tester);
    }

    const area180Typed = [
      'calc_key_one',
      'calc_key_eight',
      'calc_key_zero',
      'calc_key_feet',
      'calc_key_feet',
    ];

    testWidgets('after Area 180ft² the folded panel shows the sheet table: '
        'one row per stored size with its count (walkthrough 11.3)', (
      tester,
    ) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      for (final key in const [
        'calc_key_Length',
        'calc_key_two',
        'calc_key_zero',
        'calc_key_feet',
        'calc_key_Height',
        'calc_key_nine',
        'calc_key_feet',
      ]) {
        await press(tester, key);
      }
      await tester.tap(find.byKey(CoreResultButton.testKey));
      await typeAndFold(tester, const []);

      expect(inPanel(l10n.calculatorSheetTableTitle('180ft²')), findsOneWidget);
      expect(inPanel(l10n.calculatorSheetTableSizeColumn), findsOneWidget);
      expect(inPanel(l10n.calculatorSheetTableCountColumn), findsOneWidget);
      for (final (size, count) in const [
        ('48in x 96in', '5.63'),
        ('48in x 108in', '5.00'),
        ('48in x 120in', '4.50'),
      ]) {
        expect(inPanel(size), findsOneWidget);
        expect(inPanel(count), findsOneWidget);
      }
    });

    testWidgets('a typed 180ft² has no tiles to show but folds to the sheet '
        'table', (tester) async {
      await pumpPage(tester);
      final l10n = l10nOf(tester);
      await typeAndFold(tester, area180Typed);

      expect(find.byKey(panel), findsOneWidget);
      expect(inPanel(l10n.calculatorSheetTableTitle('180ft²')), findsOneWidget);
      expect(inPanel('48in x 96in'), findsOneWidget);
    });

    testWidgets('the trash button deletes a row: it leaves the table and its '
        'chip leaves the strip, and the value stays', (tester) async {
      await pumpPage(tester);
      await typeAndFold(tester, area180Typed);
      final bloc = blocOf(tester);
      final tape = bloc.state.tape;
      Finder onTheStrip108() => find.descendant(
        of: find.byType(CoreSuggestionArea),
        matching: find.textContaining('48in x 108in', findRichText: true),
      );
      expect(onTheStrip108(), findsOneWidget);

      await tester.tap(
        find.byKey(
          CoreGeometryArea.deleteRowKey(sheetTableId, 'sheet_48x108in'),
        ),
      );
      await settle(tester);

      expect(inPanel('48in x 108in'), findsNothing);
      expect(inPanel('48in x 96in'), findsOneWidget);
      expect(inPanel('48in x 120in'), findsOneWidget);
      expect(onTheStrip108(), findsNothing);
      expect(bloc.state.tape, tape);
    });

    testWidgets('a full swipe deletes a row and the table redraws without it '
        '(Section 1.4: "swiped to delete")', (tester) async {
      await pumpPage(tester);
      await typeAndFold(tester, area180Typed);

      await tester.drag(inPanel('48in x 120in'), const Offset(-600, 0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(inPanel('48in x 120in'), findsNothing);
      expect(inPanel('48in x 96in'), findsOneWidget);
    });

    testWidgets('swiping the first of two rows with one size removes that row '
        'alone: the other stays on the table and no error is thrown (B1)', (
      tester,
    ) async {
      final stores = FakeTradeStoresRepository();
      addTearDown(stores.dispose);
      await tester.runAsync(() async {
        final sheets = await stores
            .watchSizes(SizeStore.sheet, MeasurementSystem.imperial)
            .first;
        await stores.addSize(sheets.first);
      });
      await pumpPage(tester, stores: stores);
      await typeAndFold(tester, area180Typed);
      expect(inPanel('48in x 96in'), findsNWidgets(2));

      await tester.drag(
        find.ancestor(
          of: find.byKey(
            CoreGeometryArea.deleteRowKey(sheetTableId, 'sheet_48x96in'),
          ),
          matching: find.byType(Dismissible),
        ),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(inPanel('48in x 96in'), findsOneWidget);
      expect(inPanel('48in x 108in'), findsOneWidget);
      expect(inPanel('48in x 120in'), findsOneWidget);
    });
  });
}
