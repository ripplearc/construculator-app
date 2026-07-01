import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_files_section.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CostFilesSection(files: files),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CostFilesSection Screenshot Tests', () {
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
      );

      await expectLater(
        find.byType(CostFilesSection),
        matchesGoldenFile(
          'goldens/cost_files_section/${size.width}x${size.height}/with_files.png',
        ),
      );
    });

    testWidgets('renders empty state correctly', (tester) async {
      await pumpCostFilesSection(tester: tester, files: []);

      await expectLater(
        find.byType(CostFilesSection),
        matchesGoldenFile(
          'goldens/cost_files_section/${size.width}x${size.height}/empty.png',
        ),
      );
    });
  });
}
