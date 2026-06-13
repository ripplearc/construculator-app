import 'package:construculator/features/project_settings/presentation/widgets/add_description_sheet.dart';
import 'package:construculator/features/project_settings/presentation/widgets/project_description_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 420);
  const ratio = 1.0;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(child: SingleChildScrollView(child: child)),
      );

  group('AddDescriptionSheet screenshot tests', () {
    testWidgets('empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(AddDescriptionSheet(onAdd: (_) {})));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddDescriptionSheet),
        matchesGoldenFile(
          'goldens/add_description_sheet/${size.width}x${size.height}/add_description_sheet_empty.png',
        ),
      );
    });

    testWidgets('with value', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrap(
          AddDescriptionSheet(
            initialDescription: 'Lorem ipsum dolor sit amet, consectetur',
            onAdd: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddDescriptionSheet),
        matchesGoldenFile(
          'goldens/add_description_sheet/${size.width}x${size.height}/add_description_sheet_with_value.png',
        ),
      );
    });

    testWidgets('error state when over limit', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrap(AddDescriptionSheet(onAdd: (_) {})));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(ProjectDescriptionTextField),
        'A' * 101,
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AddDescriptionSheet),
        matchesGoldenFile(
          'goldens/add_description_sheet/${size.width}x${size.height}/add_description_sheet_error.png',
        ),
      );
    });
  });
}
