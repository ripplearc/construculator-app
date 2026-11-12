import 'package:construculator/features/estimation/presentation/widgets/add_cost_bottom_bar.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  var addTaps = 0;
  var previewTaps = 0;

  setUp(() {
    addTaps = 0;
    previewTaps = 0;
  });

  Future<void> pumpBar(
    WidgetTester tester, {
    double? total = 2097.02,
    bool previewEnabled = true,
    bool isEstimateEmpty = false,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        bottomNavigationBar: AddCostBottomBar(
          total: total,
          isEstimateEmpty: isEstimateEmpty,
          onAddCost: () => addTaps++,
          onPreview: previewEnabled ? () => previewTaps++ : null,
        ),
      ),
    ),
  );

  testWidgets('shows the estimate total in dollars and cents', (tester) async {
    await pumpBar(tester, total: 497311.09);

    expect(
      tester.widget<Text>(find.byKey(AddCostBottomBar.totalKey)).data,
      r'$497,311.09',
    );
    expect(find.text(l10n.estimateTotalLabel), findsOneWidget);
  });

  testWidgets('shows a dash, not zero dollars, while the total is unknown', (
    tester,
  ) async {
    await pumpBar(tester, total: null);

    expect(
      tester.widget<Text>(find.byKey(AddCostBottomBar.totalKey)).data,
      '-',
    );
  });

  testWidgets('opens the category list from + Add cost', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.byKey(AddCostBottomBar.addCostButtonKey));

    expect(addTaps, 1);
  });

  testWidgets('keeps + Add cost tappable when Preview is disabled', (
    tester,
  ) async {
    await pumpBar(tester, previewEnabled: false);

    await tester.tap(find.byKey(AddCostBottomBar.addCostButtonKey));

    expect(addTaps, 1);
  });

  testWidgets('calls Preview when it is enabled', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.byKey(AddCostBottomBar.previewButtonKey));

    expect(previewTaps, 1);
  });

  testWidgets('greys out Preview instead of hiding it when disabled', (
    tester,
  ) async {
    await pumpBar(tester, previewEnabled: false);

    expect(find.byKey(AddCostBottomBar.previewButtonKey), findsOneWidget);
    await tester.tap(find.byKey(AddCostBottomBar.previewButtonKey));
    expect(previewTaps, 0);
  });

  testWidgets('leaves out + Add cost while the estimate is empty', (
    tester,
  ) async {
    await pumpBar(
      tester,
      total: 0,
      isEstimateEmpty: true,
      previewEnabled: false,
    );

    expect(find.byKey(AddCostBottomBar.addCostButtonKey), findsNothing);
    expect(find.byKey(AddCostBottomBar.previewButtonKey), findsOneWidget);
    expect(find.text(l10n.estimateTotalLabel), findsOneWidget);
  });

  testWidgets('puts the Total label above the amount', (tester) async {
    await pumpBar(tester);

    expect(
      tester.getBottomLeft(find.text(l10n.estimateTotalLabel)).dy,
      lessThanOrEqualTo(
        tester.getTopLeft(find.byKey(AddCostBottomBar.totalKey)).dy,
      ),
    );
  });
}
