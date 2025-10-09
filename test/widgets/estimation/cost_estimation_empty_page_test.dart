import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultMessage =
      'No estimation added. To add an estimation please click on add button';

  Widget createWidget({
    String? message,
    String? iconPath,
    double? iconWidth,
    double? iconHeight,
    double? textWidthFactor,
  }) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(
        body: CostEstimationEmptyPage(
          message: message ?? defaultMessage,
          iconPath: iconPath ?? 'assets/icons/empty_state_icon.png',
          iconWidth: iconWidth,
          iconHeight: iconHeight,
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

    testWidgets('accepts custom message', (WidgetTester tester) async {
      const customMessage = 'Custom empty state message';
      await tester.pumpWidget(createWidget(message: customMessage));
      await tester.pumpAndSettle();

      expect(find.text(customMessage), findsOneWidget);
    });

    testWidgets('accepts custom icon path', (WidgetTester tester) async {
      const customIconPath = 'assets/icons/empty_state_icon.png';
      await tester.pumpWidget(createWidget(iconPath: customIconPath));
      await tester.pumpAndSettle();

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image, isA<AssetImage>());
    });

    testWidgets('accepts custom icon dimensions', (WidgetTester tester) async {
      const customWidth = 200.0;
      const customHeight = 150.0;
      await tester.pumpWidget(
        createWidget(iconWidth: customWidth, iconHeight: customHeight),
      );
      await tester.pumpAndSettle();

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, equals(customWidth));
      expect(imageWidget.height, equals(customHeight));
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
