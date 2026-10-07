import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  Unit? picked;

  setUp(() => picked = null);

  Future<void> pumpPill(
    WidgetTester tester, {
    Unit? unit,
    bool isEnabled = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: UnitPill(
              key: const Key('unit_pill'),
              unit: unit,
              onUnitSelected: (value) => picked = value,
              isEnabled: isEnabled,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a placeholder while no unit is picked', (tester) async {
    await pumpPill(tester);

    expect(find.text('Unit'), findsOneWidget);
  });

  testWidgets('shows the name of the picked unit', (tester) async {
    await pumpPill(tester, unit: Unit.liters);

    expect(find.text('Liters'), findsOneWidget);
    expect(find.text('Unit'), findsNothing);
  });

  testWidgets('opens the unit list when tapped', (tester) async {
    await pumpPill(tester);

    await tester.tap(find.byKey(const Key('unit_pill')));
    await tester.pumpAndSettle();

    expect(find.text('Select unit'), findsOneWidget);
    expect(find.byKey(const Key('unit_option_pieces')), findsOneWidget);
    expect(find.byKey(const Key('unit_option_liters')), findsOneWidget);
  });

  testWidgets('reports the unit chosen from the list and closes it', (
    tester,
  ) async {
    await pumpPill(tester);

    await tester.tap(find.byKey(const Key('unit_pill')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('unit_option_bags')));
    await tester.tap(find.byKey(const Key('unit_option_bags')));
    await tester.pumpAndSettle();

    expect(picked, Unit.bags);
    expect(find.text('Select unit'), findsNothing);
  });

  testWidgets('reports nothing when the list is dismissed', (tester) async {
    await pumpPill(tester);

    await tester.tap(find.byKey(const Key('unit_pill')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(picked, isNull);
    expect(find.text('Select unit'), findsNothing);
  });

  testWidgets('describes itself to a screen reader', (tester) async {
    await pumpPill(tester, unit: Unit.liters);

    expect(
      tester.getSemantics(find.byKey(const Key('unit_pill'))).label,
      'Unit: Liters. Tap to change',
    );
  });

  testWidgets('does not open the list while disabled', (tester) async {
    await pumpPill(tester, isEnabled: false);

    await tester.tap(find.byKey(const Key('unit_pill')));
    await tester.pumpAndSettle();

    expect(find.text('Select unit'), findsNothing);
    expect(picked, isNull);
  });
}
