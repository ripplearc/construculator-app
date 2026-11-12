import 'dart:async';

import 'package:construculator/features/estimation/presentation/widgets/add_cost_category_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

Widget _page() => Builder(
  builder: (context) => Scaffold(
    backgroundColor: sheetSurface(context),
    body: const SizedBox.expand(),
  ),
);

void main() {
  const size = Size(412, 420);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async => loadAppFontsAll());

  Future<void> pumpApp(
    WidgetTester tester,
    ThemeData theme,
    Widget home,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('Add cost category sheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('the category list as a sheet over the estimate', (
      tester,
    ) async {
      await pumpApp(tester, theme, _page());
      unawaited(
        AddCostCategorySheet.show(tester.element(find.byType(Scaffold))),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/add_cost_category_sheet/category_list$suffix.png',
        ),
      );
    });
  });
}
