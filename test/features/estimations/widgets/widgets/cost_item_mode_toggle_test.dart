import 'package:construculator/features/estimation/presentation/widgets/cost_item_mode_toggle.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  Widget makeToggle({
    bool fromCostFile = false,
    VoidCallback? onFromCostFile,
    VoidCallback? onManually,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: CostItemModeToggle(
          fromCostFile: fromCostFile,
          onFromCostFile: onFromCostFile ?? () {},
          onManually: onManually ?? () {},
        ),
      ),
    );
  }

  group('CostItemModeToggle', () {
    testWidgets('renders both pill labels', (tester) async {
      await tester.pumpWidget(makeToggle());
      await tester.pumpAndSettle();

      expect(find.text(l10n.fromCostFileMode), findsOneWidget);
      expect(find.text(l10n.manuallyMode), findsOneWidget);
    });

    testWidgets('manually pill is selected by default', (tester) async {
      await tester.pumpWidget(makeToggle());
      await tester.pumpAndSettle();

      final manually = tester.getSemantics(find.byKey(const Key('manually_pill')));
      final fromFile = tester.getSemantics(find.byKey(const Key('from_cost_file_pill')));

      expect(manually.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(fromFile.hasFlag(SemanticsFlag.isSelected), isFalse);
    });

    testWidgets('from cost file pill is selected when fromCostFile is true', (
      tester,
    ) async {
      await tester.pumpWidget(makeToggle(fromCostFile: true));
      await tester.pumpAndSettle();

      final fromFile = tester.getSemantics(find.byKey(const Key('from_cost_file_pill')));
      final manually = tester.getSemantics(find.byKey(const Key('manually_pill')));

      expect(fromFile.hasFlag(SemanticsFlag.isSelected), isTrue);
      expect(manually.hasFlag(SemanticsFlag.isSelected), isFalse);
    });

    testWidgets('tapping from cost file pill calls onFromCostFile', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(makeToggle(onFromCostFile: () => called = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('from_cost_file_pill')));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tapping manually pill calls onManually', (tester) async {
      var called = false;
      await tester.pumpWidget(
        makeToggle(fromCostFile: true, onManually: () => called = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manually_pill')));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('tapping already-active pill does not fire its callback', (
      tester,
    ) async {
      var fromCostFileCalled = false;
      var manuallyCalled = false;
      await tester.pumpWidget(
        makeToggle(
          fromCostFile: false,
          onFromCostFile: () => fromCostFileCalled = true,
          onManually: () => manuallyCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('manually_pill')));
      await tester.pump();

      expect(manuallyCalled, isFalse);
      expect(fromCostFileCalled, isFalse);
    });
  });
}
