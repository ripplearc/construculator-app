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
    bool verifyButtonDisabled = false,
    bool isVerifying = false,
    bool isResending = false,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? createTestTheme(),
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

  group('OtpVerificationQuickSheet Screenshot Tests - Light', () {
    testWidgets('renders with verify button disabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
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
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester);

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
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
      addTearDown(tester.view.reset);
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
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester);

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      await tester.enterText(pinInput, '123456');
      await tester.pump();

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

  group('OtpVerificationQuickSheet Screenshot Tests - Dark', () {
    testWidgets('renders with verify button disabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);
      await pumpOtpSheet(
        tester: tester,
        verifyButtonDisabled: true,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_disabled_dark.png',
        ),
      );
    });

    testWidgets('renders with verify button enabled', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester, theme: createTestThemeDark());

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      await tester.enterText(pinInput, '123456');
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verify_enabled_dark.png',
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
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_resending_dark.png',
        ),
      );
    });

    testWidgets('renders with verifying state', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await pumpOtpSheet(tester: tester, theme: createTestThemeDark());

      final pinInput = find.byKey(const Key('pin_input'));
      expect(pinInput, findsOneWidget);
      await tester.enterText(pinInput, '123456');
      await tester.pump();

      await pumpOtpSheet(
        tester: tester,
        isVerifying: true,
        verifyButtonDisabled: true,
        theme: createTestThemeDark(),
      );

      await expectLater(
        find.byType(OtpVerificationQuickSheet),
        matchesGoldenFile(
          'goldens/otp_verification_sheet/${size.width}x${size.height}/otp_verification_sheet_verifying_dark.png',
        ),
      );
    });
  });
}
