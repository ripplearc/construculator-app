import 'package:construculator/features/dashboard/domain/entities/cost_file_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/cost_file_item.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 90);
  const ratio = 1.0;

  setUp(() async {
    await loadAppFontsAll();
  });

  Future<void> pumpCostFileItem({
    required WidgetTester tester,
    required CostFile file,
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
            padding: const EdgeInsets.all(12),
            child: CostFileItem(file: file),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CostFileItem Screenshot Tests', () {
    testWidgets('renders normal file correctly', (tester) async {
      await pumpCostFileItem(
        tester: tester,
        file: CostFile(
          id: 'file-1',
          fileName: 'Major Material Cost.xls',
          fileSizeInBytes: 204800,
          uploadedAt: DateTime(2024, 4, 23),
        ),
      );

      await expectLater(
        find.byType(CostFileItem),
        matchesGoldenFile(
          'goldens/cost_file_item/${size.width}x${size.height}/normal.png',
        ),
      );
    });

    testWidgets('renders long file name correctly', (tester) async {
      await pumpCostFileItem(
        tester: tester,
        file: CostFile(
          id: 'file-2',
          fileName: 'Very Long Construction Project Material Cost Estimation Document.xlsx',
          fileSizeInBytes: 1572864,
          uploadedAt: DateTime(2024, 4, 23),
        ),
      );

      await expectLater(
        find.byType(CostFileItem),
        matchesGoldenFile(
          'goldens/cost_file_item/${size.width}x${size.height}/long_name.png',
        ),
      );
    });
  });
}
