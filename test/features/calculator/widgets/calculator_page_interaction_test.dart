import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import '../utils/calculator_test_harness.dart';

void main() {
  // A save with no profile signed in raises an error toast, whose timer
  // would outlive the test.
  setUp(CoreToast.disableTimers);

  tearDown(() {
    CoreToast.cleanup();
    CoreToast.enableTimers();
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalculatorPage(calculatorBlocFactory: calculatorBlocForTests),
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

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(CoreKeyboard)))!;

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
    expect(bloc.state.isTyping, isTrue);

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
    expect(bloc.state.isTyping, isFalse);

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

  group('W1: the settings', () {
    late CalculatorTestHarness harness;

    setUp(() => harness = CalculatorTestHarness());

    tearDown(() => harness.dispose());

    Future<void> pumpSignedIn(
      WidgetTester tester, {
      bool signedIn = true,
    }) async {
      if (signedIn) harness.signIn(harness.userWith({}));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: CoreTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CalculatorPage(calculatorBlocFactory: harness.createBloc),
        ),
      );
    }

    String pillLabel(WidgetTester tester) => tester
        .widget<CoreButton>(find.byKey(CalculatorPage.unitsPillKey))
        .label!;

    testWidgets('the System of units pill reads Imperial on the empty tape '
        'row, hides while anything is typed, and one tap switches it with '
        'the choice kept (S121)', (tester) async {
      await pumpSignedIn(tester);
      final bloc = blocOf(tester);
      final l10n = l10nOf(tester);

      expect(pillLabel(tester), l10n.calculatorUnitsImperial);
      expect(
        tester.getSemantics(find.byKey(CalculatorPage.unitsPillKey)).hint,
        l10n.calculatorUnitsSwitchToMetric,
      );

      await press(tester, 'calc_key_five');
      expect(find.byKey(CalculatorPage.unitsPillKey), findsNothing);

      await press(tester, 'calc_key_clearAll');
      expect(pillLabel(tester), l10n.calculatorUnitsImperial);

      await tester.tap(find.byKey(CalculatorPage.unitsPillKey));
      await tester.pump();
      expect(pillLabel(tester), l10n.calculatorUnitsMetric);
      expect(bloc.state.currentUnitSystem, UnitSystem.metric);
      expect(
        tester
            .widget<CoreKeyboard>(find.byType(CoreKeyboard))
            .currentUnitSystem,
        UnitSystem.metric,
      );
      expect(find.text(l10n.calculatorSettingUpdatedMessage), findsNothing);

      await press(tester, 'calc_key_five');
      await press(tester, 'calc_key_clearAll');
      expect(pillLabel(tester), l10n.calculatorUnitsMetric);

      await press(tester, 'calc_key_paren');
      expect(find.byKey(CalculatorPage.unitsPillKey), findsNothing);
    });

    testWidgets('a setting sheet opens with the tick on the current choice, '
        'Update writes the setting, re-renders the result and toasts '
        '(walkthrough 22.2)', (tester) async {
      await pumpSignedIn(tester);
      final bloc = blocOf(tester);
      final l10n = l10nOf(tester);
      for (final key in const [
        'calc_key_one',
        'calc_key_zero',
        'calc_key_inch',
        'calc_key_divide',
        'calc_key_three',
      ]) {
        await press(tester, key);
      }
      await tester.tap(find.byKey(CoreResultButton.testKey));
      await tester.pump();
      expect(bloc.state.valueText, '0ft 3-5/16in');

      bloc.add(
        const CalculatorSettingSheetOpened(
          CalculatorSetting.fractionResolution,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.text(l10n.calculatorSettingFractionResolution),
        findsOneWidget,
      );
      expect(find.text(l10n.calculatorOptionFraction(16)), findsOneWidget);
      expect(
        tester.getSemantics(
          find.byKey(CalculatorPage.settingOptionKey('sixteenth')),
        ),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );

      await tester.tap(find.byKey(CalculatorPage.settingOptionKey('half')));
      await tester.pump();
      await tester.tap(find.byKey(CalculatorPage.settingUpdateKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(bloc.state.openSettingSheet, isNull);
      expect(bloc.state.valueText, '0ft 3-1/2in');
      expect(
        find.text(l10n.calculatorSettingFractionResolution),
        findsOneWidget,
      );
      expect(find.text(l10n.calculatorSettingUpdatedMessage), findsOneWidget);
      expect(find.byKey(CalculatorPage.settingUpdateKey), findsNothing);
    });

    testWidgets('a sheet closed without Update changes nothing', (
      tester,
    ) async {
      await pumpSignedIn(tester);
      final bloc = blocOf(tester);
      final l10n = l10nOf(tester);

      bloc.add(
        const CalculatorSettingSheetOpened(CalculatorSetting.densityUnit),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text(l10n.calculatorSettingDensityDisplayUnit),
        findsOneWidget,
      );
      expect(
        find.text(l10n.calculatorOptionDensityKilogramsPerCubicMetre),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel(l10n.calculatorSettingBack));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(bloc.state.openSettingSheet, isNull);
      expect(bloc.state.tape.preferences, CalculatorPreferences.defaults);
      expect(find.text(l10n.calculatorSettingUpdatedMessage), findsNothing);
    });

    testWidgets('a choice that could not be saved stays on screen and says '
        'so', (tester) async {
      await pumpSignedIn(tester, signedIn: false);
      final bloc = blocOf(tester);
      final l10n = l10nOf(tester);

      bloc.add(
        const CalculatorSettingSheetOpened(CalculatorSetting.tonDefinition),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(CalculatorPage.settingOptionKey('longTon')));
      await tester.pump();
      await tester.tap(find.byKey(CalculatorPage.settingUpdateKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(bloc.state.tape.preferences.tonDefinition, TonDefinition.longTon);
      expect(find.text(l10n.calculatorSettingSaveFailed), findsOneWidget);
      expect(find.text(l10n.calculatorSettingUpdatedMessage), findsNothing);
    });

    testWidgets('the tick follows a setting synced from another device while '
        'the sheet is open', (tester) async {
      await pumpSignedIn(tester);
      final bloc = blocOf(tester);

      bloc.add(
        const CalculatorSettingSheetOpened(
          CalculatorSetting.fractionResolution,
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        tester.getSemantics(
          find.byKey(CalculatorPage.settingOptionKey('sixteenth')),
        ),
        isSemantics(isSelected: true),
      );

      harness.announce(
        harness.userWith({
          'calculator': {'fractional_resolution': 2},
        }),
      );
      await tester.pump();
      await tester.pump();

      expect(
        tester.getSemantics(
          find.byKey(CalculatorPage.settingOptionKey('half')),
        ),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(
          find.byKey(CalculatorPage.settingOptionKey('sixteenth')),
        ),
        isSemantics(isSelected: false),
      );
    });
  });
}
