import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/screenshot/font_loader.dart';

void main() {
  final size = const Size(390, 400);
  final ratio = 1.0;
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await loadAppFonts();
  });

  Future<void> pumpOtpSheet({
    required WidgetTester tester,
    required ThemeData theme,
    bool verifyButtonDisabled = false,
    bool isVerifying = false,
    bool isResending = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  screenshotThemeGroups('OtpVerificationQuickSheet Screenshot Tests', (
    theme,
    suffix,
  ) {
    testWidgets('renders with verify button disabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpOtpSheet(
        tester: tester,
        verifyButtonDisabled: true,
        theme: theme,
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_disabled$suffix.png',
        ),
      );
    });

    testWidgets('renders with verify button enabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester, theme: theme);

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      await tester.enterText(pinInput, '123456');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_enabled$suffix.png',
        ),
      );
    });

    testWidgets('renders with resending state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpOtpSheet(
        tester: tester,
        isResending: true,
        verifyButtonDisabled: true,
        theme: theme,
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_resending$suffix.png',
        ),
      );
    });

    testWidgets('renders with verifying state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester, theme: theme);

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      await tester.enterText(pinInput, '123456');
      await tester.pump();

      await pumpOtpSheet(
        tester: tester,
        isVerifying: true,
        verifyButtonDisabled: true,
        theme: theme,
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verifying$suffix.png',
        ),
      );
    });
  });
}
