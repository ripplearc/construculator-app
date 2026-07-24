import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_widget.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 844);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpCostEstimationEmptyPage({
    required WidgetTester tester,
    String? message,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        home: Builder(
          builder: (ctx) => Scaffold(
            backgroundColor: ctx.colorTheme.pageBackground,
            body: CostEstimationEmptyWidget(
              message:
                  message ??
                  'No estimation added To add an estimation please click on add button',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await loadAppFontsAll();
  });

  group('CostEstimationEmptyPage Screenshot Tests - Light', () {
    testWidgets('renders with custom message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message: 'No data available. Please add some content to get started.',
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_widget/${size.width}x${size.height}/cost_estimation_empty_widget_custom_message.png',
        ),
      );
    });

    testWidgets('renders with long message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message:
            'This is a very long message that should wrap to multiple lines and demonstrate how the widget handles text overflow and proper spacing between elements.',
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_widget/${size.width}x${size.height}/cost_estimation_empty_widget_long_message.png',
        ),
      );
    });
  });

  group('CostEstimationEmptyPage Screenshot Tests - Dark', () {
    testWidgets('renders with custom message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message: 'No data available. Please add some content to get started.',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_widget/${size.width}x${size.height}/cost_estimation_empty_widget_custom_message_dark.png',
        ),
      );
    });

    testWidgets('renders with long message correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpCostEstimationEmptyPage(
        tester: tester,
        message:
            'This is a very long message that should wrap to multiple lines and demonstrate how the widget handles text overflow and proper spacing between elements.',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile(
          'goldens/cost_estimation_empty_widget/${size.width}x${size.height}/cost_estimation_empty_widget_long_message_dark.png',
        ),
      );
    });
  });
}
