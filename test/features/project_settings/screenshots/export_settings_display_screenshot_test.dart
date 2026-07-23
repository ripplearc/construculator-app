import 'package:construculator/features/project_settings/presentation/widgets/export_settings_display.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 120);
  const ratio = 1.0;

  setUpAll(() async {
    await loadAppFontsAll();
  });

  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
        theme: theme ?? createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Align(alignment: Alignment.topCenter, child: child),
              ),
            ),
          ),
        ),
      );

  group('ExportSettingsDisplay screenshot tests - Light', () {
    testWidgets('google drive state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.googleDrive,
            folderName: 'Cost estimation',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_google_drive.png',
        ),
      );
    });

    testWidgets('dropbox state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.dropbox,
            folderName: 'Cost estimation',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_dropbox.png',
        ),
      );
    });

    testWidgets('one drive state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.oneDrive,
            folderName: 'Cost estimation',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_one_drive.png',
        ),
      );
    });

    testWidgets('provider set, no folder name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.googleDrive,
            folderName: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_no_folder.png',
        ),
      );
    });

    testWidgets('no export configured state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: null,
            folderName: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_no_export.png',
        ),
      );
    });
  });

  group('ExportSettingsDisplay screenshot tests - Dark', () {
    testWidgets('google drive state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.googleDrive,
            folderName: 'Cost estimation',
          ),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_google_drive_dark.png',
        ),
      );
    });

    testWidgets('dropbox state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.dropbox,
            folderName: 'Cost estimation',
          ),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_dropbox_dark.png',
        ),
      );
    });

    testWidgets('one drive state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.oneDrive,
            folderName: 'Cost estimation',
          ),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_one_drive_dark.png',
        ),
      );
    });

    testWidgets('provider set, no folder name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: StorageProvider.googleDrive,
            folderName: null,
          ),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_no_folder_dark.png',
        ),
      );
    });

    testWidgets('no export configured state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(
          const ExportSettingsDisplay(
            storageProvider: null,
            folderName: null,
          ),
          theme: createTestThemeDark(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/export_settings_display/${size.width}x${size.height}/export_settings_display_no_export_dark.png',
        ),
      );
    });
  });
}
