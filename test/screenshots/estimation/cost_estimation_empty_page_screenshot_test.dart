import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCostEstimationEmptyPage({
    required WidgetTester tester,
    String? message,
    String? iconPath,
    double? iconWidth,
    double? iconHeight,
    double? textWidthFactor,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CostEstimationEmptyPage(
            message: message ?? 'No estimation added. To add an estimation please click on add button',
            iconPath: iconPath ?? 'assets/icons/empty_state_icon.png',
            iconWidth: iconWidth,
            iconHeight: iconHeight,
            textWidthFactor: textWidthFactor,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await loadAppFonts();
  });

  group('CostEstimationEmptyPage Screenshot Tests', () {
    testWidgets('renders with custom message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message: 'No data available. Please add some content to get started.',
      );

      await expectLater(
        find.byType(CostEstimationEmptyPage),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_page/${size.width}x${size.height}/cost_estimation_empty_page_custom_message.png',
        ),
      );
    });

    testWidgets('renders with custom icon dimensions correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpCostEstimationEmptyPage(
        tester: tester,
        iconWidth: 200.0,
        iconHeight: 160.0,
      );

      await expectLater(
        find.byType(CostEstimationEmptyPage),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_page/${size.width}x${size.height}/cost_estimation_empty_page_custom_icon_size.png',
        ),
      );
    });

    testWidgets('renders with custom text width factor correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpCostEstimationEmptyPage(
        tester: tester,
        textWidthFactor: 0.5,
      );

      await expectLater(
        find.byType(CostEstimationEmptyPage),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_page/${size.width}x${size.height}/cost_estimation_empty_page_custom_text_width.png',
        ),
      );
    });

    testWidgets('renders with long message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message: 'This is a very long message that should wrap to multiple lines and demonstrate how the widget handles text overflow and proper spacing between elements.',
      );

      await expectLater(
        find.byType(CostEstimationEmptyPage),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_page/${size.width}x${size.height}/cost_estimation_empty_page_long_message.png',
        ),
      );
    });
  });
}
