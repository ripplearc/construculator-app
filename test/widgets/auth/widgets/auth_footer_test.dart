import 'package:construculator/features/auth/presentation/widgets/auth_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  const text = 'Don’t have an account?';
  const actionText = 'Sign up';

  Future<void> pumpFooterWidget({
    required WidgetTester tester,
    required VoidCallback onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[
            AppColorsExtension.create(),
            AppTypographyExtension.create(),
          ],
        ),
        home: Scaffold(
          body: AuthFooter(
            text: text,
            actionText: actionText,
            onPressed: onPressed,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AuthFooter Widget Tests', () {
    testWidgets(
      'renders actionText inside WidgetSpan correctly as tappable Text',
      (tester) async {
        await pumpFooterWidget(tester: tester, onPressed: () {});
        final context = tester.element(find.byType(AuthFooter));

        final actionTextFinder = find.text(actionText);
        expect(actionTextFinder, findsOneWidget);
        final colors = AppColorsExtension.of(context);

        final textWidget = tester.widget<Text>(actionTextFinder);
        expect(textWidget.style!.color, colors.textLink);

        final typography = Theme.of(context).coreTypography;

        expect(
          textWidget.style!.fontWeight,
          typography.bodyMediumSemiBold.fontWeight,
        );
      },
    );

    testWidgets('tapping on actionText triggers the callback', (tester) async {
      bool tapped = false;

      await pumpFooterWidget(tester: tester, onPressed: () => tapped = true);

      final tappableText = find.byKey(const Key('auth_footer_link'));
      expect(tappableText, findsOneWidget);

      await tester.tap(tappableText);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('has correct container layout and color', (tester) async {
      await pumpFooterWidget(tester: tester, onPressed: () {});
      final context = tester.element(find.byType(AuthFooter));
      final colors = AppColorsExtension.of(context);
      final containerFinder = find.byType(Container);
      final container = tester.widget<Container>(containerFinder);
      expect(container.color, colors.backgroundBlueLight);
      expect(container.constraints!.minHeight, CoreSpacing.space16);
    });

    testWidgets('uses SafeArea to avoid bottom insets', (tester) async {
      await pumpFooterWidget(tester: tester, onPressed: () {});
      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
}
