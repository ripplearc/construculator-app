import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultMessage =
      'No estimation added. To add an estimation please click on add button';

  Widget createWidget({String? message, double? textWidthFactor}) {
    return MaterialApp(
      theme: CoreTheme.light(),
      home: Scaffold(
        body: CostEstimationEmptyPage(
          message: message ?? defaultMessage,
          textWidthFactor: textWidthFactor,
        ),
      ),
    );
  }

  group('CostEstimationEmptyPage', () {
    testWidgets('renders with default message', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CostEstimationEmptyPage), findsOneWidget);
      expect(find.text(defaultMessage), findsOneWidget);
    });

    testWidgets('renders the empty estimation icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final iconFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CoreIconWidget &&
            widget.icon == CoreIcons.emptyEstimation,
      );

      expect(iconFinder, findsOneWidget);
    });

    testWidgets('accepts custom message', (WidgetTester tester) async {
      const customMessage = 'Custom empty state message';
      await tester.pumpWidget(createWidget(message: customMessage));
      await tester.pumpAndSettle();

      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('accepts custom textWidthFactor', (WidgetTester tester) async {
      const customTextWidthFactor = 0.5;
      await tester.pumpWidget(
        createWidget(textWidthFactor: customTextWidthFactor),
      );
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final textContainer = sizedBoxes.last;
      final screenWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final expectedWidth = screenWidth * customTextWidthFactor;

      expect(textContainer.width, equals(expectedWidth));
    });
  });
}
