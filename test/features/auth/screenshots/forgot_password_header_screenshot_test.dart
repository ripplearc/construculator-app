import 'package:construculator/features/auth/presentation/widgets/forgot_password_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 150);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpForgotPasswordHeader({
    required WidgetTester tester,
    required String title,
    required String description,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
        home: Material(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ForgotPasswordHeader(
              title: title,
              description: description,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ForgotPasswordHeader Screenshot Tests - Light', () {
    testWidgets('renders forgot password header correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpForgotPasswordHeader(
        tester: tester,
        title: 'Forgot Password?',
        description:
            'An OTP will be sent to your registered email ID to reset your password',
      );

      await expectLater(
        find.byType(ForgotPasswordHeader),
        matchesGoldenFile(
          'goldens/forgot_password_header/${size.width}x${size.height}/forgot_password_header.png',
        ),
      );
    });
  });

  group('ForgotPasswordHeader Screenshot Tests - Dark', () {
    testWidgets('renders forgot password header correctly', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpForgotPasswordHeader(
        tester: tester,
        title: 'Forgot Password?',
        description:
            'An OTP will be sent to your registered email ID to reset your password',
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(ForgotPasswordHeader),
        matchesGoldenFile(
          'goldens/forgot_password_header/${size.width}x${size.height}/forgot_password_header_dark.png',
        ),
      );
    });
  });
}
