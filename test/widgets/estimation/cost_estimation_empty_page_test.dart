import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_empty_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaultMessage = 'No estimation added. To add an estimation please click on add button';
  const defaultIconWidth = 140.0;
  const defaultIconHeight = 112.5;
  const defaultTextWidthFactor = 0.7;

  Widget createWidget({
      String? message,
      String? iconPath,
      double? iconWidth,
      double? iconHeight,
      double? textWidthFactor,
    }) {
        return MaterialApp(
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
    group('Basic Rendering', () {
      testWidgets('renders with default properties', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(CostEstimationEmptyPage), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Image), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
      });

      testWidgets('displays the correct message', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.text(defaultMessage), findsOneWidget);
      });

      testWidgets('displays custom message', (WidgetTester tester) async {
        const customMessage = 'Custom empty state message';
        await tester.pumpWidget(createWidget(message: customMessage));
        await tester.pumpAndSettle();

        expect(find.text(customMessage), findsOneWidget);
        expect(find.text(defaultMessage), findsNothing);
      });
    });

    group('Image Properties', () {
      testWidgets('displays image with default properties', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<AssetImage>());
        expect(imageWidget.width, equals(defaultIconWidth));
        expect(imageWidget.height, equals(defaultIconHeight));
      });

      testWidgets('displays image with custom properties', (WidgetTester tester) async {
        const customIconPath = 'assets/icons/empty_state_icon.png'; // Use existing icon
        const customWidth = 200.0;
        const customHeight = 150.0;

        await tester.pumpWidget(createWidget(
          iconPath: customIconPath,
          iconWidth: customWidth,
          iconHeight: customHeight,
        ));
        await tester.pumpAndSettle();

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<AssetImage>());
        expect(imageWidget.width, equals(customWidth));
        expect(imageWidget.height, equals(customHeight));
      });
    });

    group('Text Properties', () {
      testWidgets('applies correct text styling', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final textWidget = tester.widget<Text>(find.byType(Text));
        final textStyle = textWidget.style;

        expect(textStyle, isNotNull);
        expect(textStyle!.fontSize, equals(16));
        expect(textStyle.fontWeight, equals(FontWeight.w500));
        expect(textWidget.textAlign, equals(TextAlign.center));
      });

      testWidgets('text width is constrained by textWidthFactor', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final textContainer = sizedBoxes.last; // The last SizedBox contains the text
        final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
        final expectedWidth = screenWidth * defaultTextWidthFactor;

        expect(textContainer.width, equals(expectedWidth));
      });

      testWidgets('text width uses custom textWidthFactor', (WidgetTester tester) async {
        const customTextWidthFactor = 0.5;
        await tester.pumpWidget(createWidget(textWidthFactor: customTextWidthFactor));
        await tester.pumpAndSettle();

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final textContainer = sizedBoxes.last; // The last SizedBox contains the text
        final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
        final expectedWidth = screenWidth * customTextWidthFactor;

        expect(textContainer.width, equals(expectedWidth));
      });
    });

    group('Layout Structure', () {
      testWidgets('has correct column structure', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
        expect(column.children.length, equals(3)); // Image, SizedBox, SizedBox with Text
      });

      testWidgets('has correct spacing between elements', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        expect(sizedBoxes.length, equals(2)); // Spacing and text container

        // Check spacing between image and text
        final spacingBox = sizedBoxes.first;
        expect(spacingBox.height, equals(24));
      });
    });

    group('Accessibility', () {
      testWidgets('has semantic structure', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pumpAndSettle();

        expect(find.byType(CostEstimationEmptyPage), findsOneWidget);
        expect(find.byType(Center), findsOneWidget);
        expect(find.byType(Column), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('handles empty message', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(message: ''));
        await tester.pumpAndSettle();

        expect(find.text(''), findsOneWidget);
      });

      testWidgets('handles very long message', (WidgetTester tester) async {
        const longMessage = 'This is a very long message that should be displayed properly and should wrap to multiple lines if necessary to fit within the constrained width of the text container';
        await tester.pumpWidget(createWidget(message: longMessage));
        await tester.pumpAndSettle();

        expect(find.text(longMessage), findsOneWidget);
      });

      testWidgets('handles zero icon dimensions', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(
          iconWidth: 0,
          iconHeight: 0,
        ));
        await tester.pumpAndSettle();

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.width, equals(0));
        expect(imageWidget.height, equals(0));
      });

      testWidgets('handles textWidthFactor of 1.0', (WidgetTester tester) async {
        await tester.pumpWidget(createWidget(textWidthFactor: 1.0));
        await tester.pumpAndSettle();

        final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
        final textContainer = sizedBoxes.last; // The last SizedBox contains the text
        final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
        expect(textContainer.width, equals(screenWidth));
      });
    });
  });
}
