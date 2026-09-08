import 'package:construculator/features/project_settings/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/project_settings/presentation/widgets/cost_files_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 300);
  const ratio = 1.0;

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpCostFilesSection({
    required WidgetTester tester,
    required List<CostFile> files,
    required ThemeData theme,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CostFilesSection(files: files),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  screenshotThemeGroups('CostFilesSection Screenshot Tests', (theme, suffix) {
    testWidgets('renders with files correctly', (tester) async {
      await pumpCostFilesSection(
        tester: tester,
        files: [
          CostFile(
            id: 'file-1',
            fileName: 'Major Material Cost.xls',
            fileSizeInBytes: 204800,
            uploadedAt: DateTime(2024, 4, 23),
          ),
          CostFile(
            id: 'file-2',
            fileName: 'Foundation Budget.xlsx',
            fileSizeInBytes: 1572864,
            uploadedAt: DateTime(2024, 3, 10),
          ),
        ],
        theme: theme,
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_files_section/${size.width}x${size.height}/with_files$suffix.png',
        ),
      );
    });

    testWidgets('renders empty state correctly', (tester) async {
      await pumpCostFilesSection(tester: tester, files: [], theme: theme);

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_files_section/${size.width}x${size.height}/empty$suffix.png',
        ),
      );
    });
  });
}
