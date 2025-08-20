import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

import '../font_loader.dart';

void main() {
  final size = const Size(390, 400);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  group('OtpVerificationQuickSheet Screenshot Tests', () {
    Future<void> pumpOtpSheet({
      required WidgetTester tester,
      bool verifyButtonDisabled = false,
      bool isVerifying = false,
      bool isResending = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: OtpVerificationQuickSheet(
              note: 'Enter 6 digit code we just texted to your email ID ',
              contact: 'johndoe@gmail.com',
              onChanged: (_) {},
              onVerify: () {},
              onResend: () {},
              onEdit: () {},
              verifyButtonDisabled: verifyButtonDisabled,
              isVerifying: isVerifying,
              isResending: isResending,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders with verify button disabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpOtpSheet(tester: tester, verifyButtonDisabled: true);

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_disabled.png',
        ),
      );
    });

    testWidgets('renders with verify button enabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      await pumpOtpSheet(tester: tester);

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      // Type a 6-digit code
      await tester.enterText(pinInput, '123456');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_enabled.png',
        ),
      );
    });

    testWidgets('renders with resending state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      await pumpOtpSheet(
        tester: tester,
        isResending: true,
        verifyButtonDisabled: true,
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_resending.png',
        ),
      );
    });

    testWidgets('renders with verifying state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;

      // First pump with enabled state to get the input field
      await pumpOtpSheet(tester: tester);

      // Find and fill the OTP input field
      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);

      // Type a 6-digit code
      await tester.enterText(pinInput, '123456');
      await tester.pump();

      // Now pump with verifying state to show the loading state
      await pumpOtpSheet(
        tester: tester,
        isVerifying: true,
        verifyButtonDisabled: true,
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verifying.png',
        ),
      );
    });
  });
}
