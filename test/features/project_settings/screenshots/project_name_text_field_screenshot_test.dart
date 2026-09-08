import 'package:construculator/features/project_settings/presentation/widgets/project_name_text_field.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 120);
  const ratio = 1.0;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(Widget child, {required ThemeData theme}) => MaterialApp(
        theme: theme,
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

  screenshotThemeGroups('ProjectNameTextField screenshot tests', (
    theme,
    suffix,
  ) {
    testWidgets('empty state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(ProjectNameTextField(controller: controller), theme: theme),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectNameTextField),
        matchesGoldenFile(
          'goldens/project_name_text_field/${size.width}x${size.height}/project_name_text_field_empty$suffix.png',
        ),
      );
    });

    testWidgets('with value', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController(text: 'HD building');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(ProjectNameTextField(controller: controller), theme: theme),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectNameTextField),
        matchesGoldenFile(
          'goldens/project_name_text_field/${size.width}x${size.height}/project_name_text_field_with_value$suffix.png',
        ),
      );
    });

    testWidgets('required error state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(ProjectNameTextField(controller: controller), theme: theme),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(ProjectNameTextField), 'a');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(ProjectNameTextField), '');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectNameTextField),
        matchesGoldenFile(
          'goldens/project_name_text_field/${size.width}x${size.height}/project_name_text_field_error_required$suffix.png',
        ),
      );
    });

    testWidgets('too-long error state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(ProjectNameTextField(controller: controller), theme: theme),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(ProjectNameTextField), 'A' * 101);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectNameTextField),
        matchesGoldenFile(
          'goldens/project_name_text_field/${size.width}x${size.height}/project_name_text_field_error_too_long$suffix.png',
        ),
      );
    });

    testWidgets('disabled state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController(text: 'HD building');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(
          ProjectNameTextField(controller: controller, enabled: false),
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ProjectNameTextField),
        matchesGoldenFile(
          'goldens/project_name_text_field/${size.width}x${size.height}/project_name_text_field_disabled$suffix.png',
        ),
      );
    });
  });
}
