import 'package:construculator/features/global_search/presentation/widgets/global_search_filter_chip_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  const size = Size(390, 56);
  const ratio = 1.0;
  const testName = 'global_search_filter_chip_widget';
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFontsAll();
  });

  group('GlobalSearchFilterChipWidget Screenshot Tests', () {
    Future<void> pumpFilterChip({
      required WidgetTester tester,
      required String label,
      VoidCallback? onTap,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Material(
            child: Center(
              child: GlobalSearchFilterChipWidget(
                label: label,
                onTap: onTap,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders chip correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpFilterChip(
        tester: tester,
        label: 'Tags',
        onTap: () {},
      );

      await expectLater(
        find.byType(GlobalSearchFilterChipWidget),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_default.png',
        ),
      );
    });

    testWidgets('renders chip with long label correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpFilterChip(
        tester: tester,
        label: 'Recently Modified',
        onTap: () {},
      );

      await expectLater(
        find.byType(GlobalSearchFilterChipWidget),
        matchesGoldenFile(
          'goldens/$testName/${size.width}x${size.height}/${testName}_long_label.png',
        ),
      );
    });
  });
}
