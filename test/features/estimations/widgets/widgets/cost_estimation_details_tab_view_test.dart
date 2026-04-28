import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_details_tab_view.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('en'));
  });

  Widget createWidget() {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: CostEstimationDetailsTabView(),
      ),
    );
  }

  group('CostEstimationDetailsTabView', () {
    testWidgets('renders widget successfully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('cost_estimation_details_tab_view')),
        findsOneWidget,
      );
    });

    testWidgets('displays all three tabs', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text(l10n.materialsTab), findsOneWidget);
      expect(find.text(l10n.laboursTab), findsOneWidget);
      expect(find.text(l10n.equipmentsTab), findsOneWidget);
    });

    testWidgets('displays materials empty state by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('materials_empty_state')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.noMaterialCostMessage),
        findsOneWidget,
      );
    });

    testWidgets('displays empty estimation icon in materials tab', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('materials_empty_state_icon')),
        findsOneWidget,
      );
    });

    testWidgets('switches to labours tab when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.laboursTab));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('labours_empty_state')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.noLabourCostMessage),
        findsOneWidget,
      );
    });

    testWidgets('switches to equipments tab when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('equipments_empty_state')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.noEquipmentCostMessage),
        findsOneWidget,
      );
    });

    testWidgets('can switch between tabs multiple times', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.laboursTab));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.noLabourCostMessage),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.equipmentsTab));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.noEquipmentCostMessage),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.materialsTab));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.noMaterialCostMessage),
        findsOneWidget,
      );
    });

    testWidgets('maintains tab selection state', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.laboursTab));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('labours_empty_state')),
        findsOneWidget,
      );

      await tester.pump();

      expect(
        find.byKey(const Key('labours_empty_state')),
        findsOneWidget,
      );
    });

    testWidgets('displays comment icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('comment_icon')), findsOneWidget);
    });
  });
}
