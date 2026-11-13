import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/add_cost_category_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));
  CostItemType? picked;
  var wasClosed = false;

  setUp(() {
    picked = null;
    wasClosed = false;
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () async {
                picked = await AddCostCategorySheet.show(context);
                wasClosed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('lists Material, Labor and Equipment in that order', (
    tester,
  ) async {
    await openSheet(tester);

    final tops = [
      for (final type in CostItemType.values)
        tester.getTopLeft(find.byKey(AddCostCategorySheet.rowKey(type))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text(l10n.addCostSheetTitle), findsOneWidget);
    expect(find.text(l10n.addCostSheetSubtitle), findsOneWidget);
    expect(find.text(l10n.addCostCategoryMaterialSubtitle), findsOneWidget);
    expect(find.text(l10n.addCostCategoryMaterialTitle), findsOneWidget);
    expect(find.text(l10n.addCostCategoryLaborTitle), findsOneWidget);
    expect(find.text(l10n.addCostCategoryEquipmentTitle), findsOneWidget);
  });

  testWidgets('keeps the last row above the system navigation bar', (
    tester,
  ) async {
    const navigationBarHeight = 48.0;
    final ratio = tester.view.devicePixelRatio;
    tester.view.padding = FakeViewPadding(bottom: navigationBarHeight * ratio);
    tester.view.viewPadding = FakeViewPadding(
      bottom: navigationBarHeight * ratio,
    );
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await openSheet(tester);

    final lastRowBottom = tester
        .getBottomLeft(
          find.byKey(AddCostCategorySheet.rowKey(CostItemType.equipment)),
        )
        .dy;
    final usableBottom =
        tester.view.physicalSize.height / ratio - navigationBarHeight;
    expect(lastRowBottom, lessThanOrEqualTo(usableBottom));
  });

  for (final type in CostItemType.values) {
    testWidgets('returns ${type.name} when its row is tapped', (tester) async {
      await openSheet(tester);

      await tester.tap(find.byKey(AddCostCategorySheet.rowKey(type)));
      await tester.pumpAndSettle();

      expect(picked, type);
    });
  }

  testWidgets('closes with no pick when the user taps outside', (tester) async {
    await openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(wasClosed, isTrue);
    expect(picked, isNull);
  });

  testWidgets('closes with no pick when the user swipes down', (tester) async {
    await openSheet(tester);

    await tester.fling(
      find.byType(AddCostCategorySheet),
      const Offset(0, 600),
      1500,
    );
    await tester.pumpAndSettle();

    expect(wasClosed, isTrue);
    expect(picked, isNull);
  });

  testWidgets('announces the title as a heading', (tester) async {
    final handle = tester.ensureSemantics();
    await openSheet(tester);

    expect(
      tester
          .getSemantics(find.text(l10n.addCostSheetTitle))
          .getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    handle.dispose();
  });
}
