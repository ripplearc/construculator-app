import 'package:construculator/features/project_settings/presentation/widgets/validation_error_widget.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 40);
  const ratio = 1.0;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Material(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Align(alignment: Alignment.topCenter, child: child),
            ),
          ),
        ),
      );

  String goldenPath(String name) =>
      'goldens/validation_error_widget/${size.width}x${size.height}/$name.png';

  group('ValidationErrorWidget screenshot tests', () {
    testWidgets('light theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(const ValidationErrorWidget(message: 'Project name is required')),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ValidationErrorWidget),
        matchesGoldenFile(goldenPath('validation_error_widget_light')),
      );
    });

    testWidgets('dark theme', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ValidationErrorWidget(message: 'Project name is required'),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ValidationErrorWidget),
        matchesGoldenFile(goldenPath('validation_error_widget_dark')),
      );
    });
  });
}
