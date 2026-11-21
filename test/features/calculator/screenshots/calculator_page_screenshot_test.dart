import 'package:construculator/features/calculator/presentation/bloc/calculator_bloc/calculator_bloc.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 844);
  const sheetSize = Size(390, 1100);
  const ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCalculatorPage({
    required WidgetTester tester,
    required ThemeData theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalculatorPage(router: FakeAppRouter()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  setUp(() async {
    await loadAppFontsAll();
  });

  CalculatorBloc blocOf(WidgetTester tester) => BlocProvider.of<CalculatorBloc>(
    tester.element(find.byType(CoreKeyboard)),
  );

  screenshotThemeGroups('CalculatorPage Screenshot Tests', (theme, suffix) {
    testWidgets('renders initial state correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_initial$suffix.png',
        ),
      );
    });

    testWidgets('renders a tape with an input chip, a result chip, a closed '
        'bracket chip and an error chip (Section 1.1, term 2.22)', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      blocOf(tester)
        ..add(const CalculatorKeySelected('Length'))
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorUnitSelected(Unit.foot))
        ..add(const CalculatorOperatorPressed(Operator.multiply))
        ..add(const CalculatorDigitPressed('3'))
        ..add(const CalculatorUnitSelected(Unit.foot))
        ..add(const CalculatorEqualsPressed())
        ..add(const CalculatorOperatorPressed(Operator.add))
        ..add(const CalculatorControlActioned(ControlAction.paren))
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorOperatorPressed(Operator.multiply))
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorControlActioned(ControlAction.paren))
        ..add(const CalculatorOperatorPressed(Operator.add))
        ..add(const CalculatorDigitPressed('5'))
        ..add(const CalculatorUnitSelected(Unit.pound))
        ..add(const CalculatorEqualsPressed());
      await tester.pump();
      await tester.pump();

      expect(
        [for (final chip in blocOf(tester).state.chipsList) chip.type],
        containsAll([
          CoreCalculatorChipType.editable,
          CoreCalculatorChipType.result,
          CoreCalculatorChipType.bracketClosed,
          CoreCalculatorChipType.error,
        ]),
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_tape_chips$suffix.png',
        ),
      );
    });

    testWidgets('renders an open bracket chip with the chips before it dimmed '
        '(term 2.22)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      blocOf(tester)
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorOperatorPressed(Operator.add))
        ..add(const CalculatorControlActioned(ControlAction.paren))
        ..add(const CalculatorDigitPressed('3'))
        ..add(const CalculatorOperatorPressed(Operator.multiply))
        ..add(const CalculatorDigitPressed('4'));
      await tester.pump();
      await tester.pump();

      expect(
        blocOf(tester).state.chipsList.last.type,
        CoreCalculatorChipType.bracketOpen,
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_tape_open_bracket$suffix.png',
        ),
      );
    });

    testWidgets('renders a chip reopened by a tap with the result after it '
        'dashed (rule 4.8)', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      blocOf(tester)
        ..add(const CalculatorKeySelected('Length'))
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorDigitPressed('2'))
        ..add(const CalculatorUnitSelected(Unit.foot))
        ..add(const CalculatorKeySelected('Width'))
        ..add(const CalculatorDigitPressed('1'))
        ..add(const CalculatorDigitPressed('8'))
        ..add(const CalculatorUnitSelected(Unit.foot))
        ..add(const CalculatorEqualsPressed())
        ..add(const CalculatorChipTapped(1));
      await tester.pump();
      await tester.pump();

      expect(
        [for (final chip in blocOf(tester).state.chipsList) chip.type],
        [
          CoreCalculatorChipType.editable,
          CoreCalculatorChipType.active,
          CoreCalculatorChipType.dashed,
        ],
      );
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/calculator_page/${size.width}x${size.height}/calculator_page_tape_editing$suffix.png',
        ),
      );
    });

    testWidgets('renders the "View all" sheet over the page', (tester) async {
      tester.view.physicalSize = sheetSize;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      await tester.tap(find.text('View all'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/calculator_page/${sheetSize.width}x${sheetSize.height}/calculator_page_view_all_sheet$suffix.png',
        ),
      );
    });

    testWidgets('renders the "View all" sheet with the groups in a dragged '
        'order (Section 1.5)', (tester) async {
      tester.view.physicalSize = sheetSize;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCalculatorPage(tester: tester, theme: theme);

      blocOf(
        tester,
      ).add(const CalculatorGroupsReordered(oldIndex: 4, newIndex: 0));
      await tester.pump();
      await tester.tap(find.text('View all'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(
        tester
            .widget<CoreKeyboard>(find.byType(CoreKeyboard))
            .allGroups
            .first
            .name
            .id,
        CalculatorGroupId.trigonometry,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/calculator_page/${sheetSize.width}x${sheetSize.height}/calculator_page_view_all_sheet_reordered$suffix.png',
        ),
      );
    });
  });
}
