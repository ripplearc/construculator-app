import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_verification_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import '../../../screenshots/font_loader.dart';

void main() {
  const contact = '+233 123 456 789';
  const exampleCode = '123456';
  BuildContext? buildContext;

  Future<void> pumpOtpSheet({
    required WidgetTester tester,
    bool isVerifying = false,
    bool isResending = false,
    bool verifyDisabled = false,
    required void Function(String) onChanged,
    VoidCallback? onVerify,
    VoidCallback? onResend,
    VoidCallback? onEdit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: createTestTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            buildContext = context;
            return Scaffold(
              body: OtpVerificationQuickSheet(
                note: AppLocalizations.of(buildContext!)!.didNotReceiveCode,
                contact: contact,
                onChanged: onChanged,
                onEdit: onEdit,
                onVerify: onVerify,
                onResend: onResend,
                isVerifying: isVerifying,
                isResending: isResending,
                verifyButtonDisabled: verifyDisabled,
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('OtpVerificationBottomSheet Widget Tests', () {
    testWidgets('renders heading and resend/verify text correctly', (
      tester,
    ) async {
      await pumpOtpSheet(tester: tester, onChanged: (_) {});

      expect(
        find.text(AppLocalizations.of(buildContext!)!.authenticationCodeTitle),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          AppLocalizations.of(buildContext!)!.didNotReceiveCode,
        ),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.resendButton),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizations.of(buildContext!)!.verifyOtpButton),
        findsOneWidget,
      );
    });

    testWidgets('renders note and contact correctly inside RichText', (
      tester,
    ) async {
      await pumpOtpSheet(tester: tester, onChanged: (_) {});
      final richTexts = find.byType(RichText);
      final richTextWithNote = richTexts.evaluate().any((element) {
        final widget = element.widget as RichText;
        final span = widget.text as TextSpan;
        return span.toPlainText().contains(
          AppLocalizations.of(buildContext!)!.didNotReceiveCode,
        );
      });
      expect(richTextWithNote, isTrue);
      final richTextWithContact = richTexts.evaluate().any((element) {
        final widget = element.widget as RichText;
        final span = widget.text as TextSpan;
        return span.toPlainText().contains(contact);
      });
      expect(richTextWithContact, isTrue);
    });

    testWidgets('tapping contact triggers onEdit callback', (tester) async {
      bool tapped = false;
      await pumpOtpSheet(
        tester: tester,
        onChanged: (_) {},
        onEdit: () => tapped = true,
      );

      await tester.tap(find.byKey(Key('edit_contact_button')));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('typing in Pinput triggers onChanged', (tester) async {
      String code = '';
      await pumpOtpSheet(tester: tester, onChanged: (val) => code = val);

      final pinField = find.byKey(const Key('pin_input'));
      expect(pinField, findsOneWidget);
      await tester.enterText(pinField, exampleCode);
      expect(code, exampleCode);
    });

    testWidgets('resend link shows "Resending..." when isResending=true', (
      tester,
    ) async {
      await pumpOtpSheet(tester: tester, isResending: true, onChanged: (_) {});

      expect(
        find.text(AppLocalizations.of(buildContext!)!.resendingButtonLabel),
        findsOneWidget,
      );
    });

    testWidgets('tapping resend link triggers onResend', (tester) async {
      bool tapped = false;
      await pumpOtpSheet(
        tester: tester,
        onChanged: (_) {},
        onResend: () => tapped = true,
      );

      await tester.tap(
        find.text(AppLocalizations.of(buildContext!)!.resendButton),
      );
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('verify button is enabled and triggers onVerify', (
      tester,
    ) async {
      bool tapped = false;
      await pumpOtpSheet(
        tester: tester,
        onChanged: (_) {},
        onVerify: () => tapped = true,
      );

      await tester.tap(
        find.text(AppLocalizations.of(buildContext!)!.verifyOtpButton),
      );
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('verify button shows "Verifying..." when isVerifying=true', (
      tester,
    ) async {
      await pumpOtpSheet(tester: tester, onChanged: (_) {}, isVerifying: true);

      expect(
        find.text(AppLocalizations.of(buildContext!)!.verifyingButtonLabel),
        findsOneWidget,
      );
    });

    testWidgets('verify button is disabled when verifyButtonDisabled=true', (
      tester,
    ) async {
      await pumpOtpSheet(
        tester: tester,
        onChanged: (_) {},
        verifyDisabled: true,
      );

      final button = tester.widget<CoreButton>(find.byType(CoreButton));
      expect(button.isDisabled, isTrue);
    });
  });
}
