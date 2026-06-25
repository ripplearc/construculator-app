import 'package:construculator/features/project_settings/presentation/widgets/export_settings_display.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart' show CoreTheme;

void main() {
  Future<void> pumpExportSettingsDisplay(
    WidgetTester tester, {
    StorageProvider? storageProvider,
    String? folderName,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CoreTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ExportSettingsDisplay(
              storageProvider: storageProvider,
              folderName: folderName,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ExportSettingsDisplay', () {
    group('Rendering', () {
      testWidgets('always shows section title', (tester) async {
        await pumpExportSettingsDisplay(tester);

        expect(find.text('Folder link for export'), findsOneWidget);
      });

      testWidgets('hides provider row when storageProvider is null', (
        tester,
      ) async {
        await pumpExportSettingsDisplay(tester);

        expect(
          find.byKey(const Key('export_settings_provider_icon')),
          findsNothing,
        );
      });

      testWidgets('shows Google Drive label for googleDrive provider', (
        tester,
      ) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.googleDrive,
          folderName: 'Cost estimation',
        );

        expect(find.text('Google drive link:'), findsOneWidget);
      });

      testWidgets('shows Dropbox label for dropbox provider', (tester) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.dropbox,
          folderName: 'Cost estimation',
        );

        expect(find.text('Dropbox link:'), findsOneWidget);
      });

      testWidgets('shows One Drive label for oneDrive provider', (
        tester,
      ) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.oneDrive,
          folderName: 'Cost estimation',
        );

        expect(find.text('One drive link:'), findsOneWidget);
      });

      testWidgets('shows folder name in chip when folderName is provided', (
        tester,
      ) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.googleDrive,
          folderName: 'Cost estimation',
        );

        expect(find.text('Cost estimation'), findsOneWidget);
      });

      testWidgets('hides folder chip when folderName is null', (tester) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.googleDrive,
        );

        expect(find.text('Cost estimation'), findsNothing);
      });

      testWidgets('shows provider icon when provider is set', (tester) async {
        await pumpExportSettingsDisplay(
          tester,
          storageProvider: StorageProvider.googleDrive,
          folderName: 'My folder',
        );

        expect(
          find.byKey(const Key('export_settings_provider_icon')),
          findsOneWidget,
        );
      });
    });
  });
}
