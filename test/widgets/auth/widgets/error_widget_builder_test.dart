import 'package:construculator/features/auth/presentation/widgets/error_widget_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  const errorText = 'Something went wrong';
  const linkText = 'Retry';

  Widget pumpErrorBuilder({
    String? error,
    String? link,
    required VoidCallback onPressed,
  }) {
    return MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[TypographyExtension.create()],
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: buildErrorWidgetWithLink(
                context: context,
                errorText: error,
                linkText: link,
                onPressed: onPressed,
              ),
            );
          },
        ),
      ),
    );
  }

  group('buildErrorWidget Tests', () {
    testWidgets('renders errorText correctly with proper style', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpErrorBuilder(error: errorText, link: null, onPressed: () {}),
      );

      final errorFinder = find.text(errorText);
      expect(errorFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(errorFinder);
      expect(textWidget.style!.color, CoreTextColors.error);

      final context = tester.element(find.byType(Center));
      final typography =
          Theme.of(context).coreTypography;

      expect(
        textWidget.style!.fontWeight,
        typography.bodySmallRegular.fontWeight,
      );
    });

    testWidgets('renders linkText when provided with correct style', (
      tester,
    ) async {
      await tester.pumpWidget(
        pumpErrorBuilder(error: errorText, link: linkText, onPressed: () {}),
      );

      final linkFinder = find.text(linkText);
      expect(linkFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(linkFinder);
      expect(textWidget.style!.color, CoreTextColors.link);

      final context = tester.element(find.byType(Center));
      final typography = Theme.of(context).coreTypography;

      expect(
        textWidget.style!.fontWeight,
        typography.bodySmallSemiBold.fontWeight,
      );
    });

    testWidgets('does not render linkText when null', (tester) async {
      await tester.pumpWidget(
        pumpErrorBuilder(error: errorText, link: null, onPressed: () {}),
      );

      expect(find.text(linkText), findsNothing);
    });

    testWidgets('tapping linkText triggers onPressed callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        pumpErrorBuilder(
          error: errorText,
          link: linkText,
          onPressed: () => tapped = true,
        ),
      );

      final tapTarget = find.byKey(const Key(linkText));
      expect(tapTarget, findsOneWidget);

      await tester.tap(tapTarget);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets(
      'builds inside a Row with Flexible and GestureDetector correctly',
      (tester) async {
        await tester.pumpWidget(
          pumpErrorBuilder(error: errorText, link: linkText, onPressed: () {}),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Flexible), findsOneWidget);
        expect(find.byType(GestureDetector), findsOneWidget);
      },
    );
  });
}
