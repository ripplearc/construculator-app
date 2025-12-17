import 'package:construculator/features/auth/presentation/widgets/otp_quick_sheet/otp_quick_sheet_body.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A widget that displays the OTP verification sheet
/// [note] - The note to display
/// [contact] - The contact to display
/// [verifyButtonDisabled] - Whether the verify button should be disabled
/// [isVerifying] - Whether the OTP verification is in progress
/// [isResending] - Whether the OTP resend is in progress
/// [onChanged] - The callback to be called when user types in the OTP
/// [onVerify] - The callback to be called when user taps the verify button
/// [onResend] - The callback to be called when user taps the resend button
/// [onEdit] - The callback to be called when user taps the edit button

class OtpVerificationQuickSheet extends StatelessWidget {
  final String note;
  final String contact;
  final bool verifyButtonDisabled;
  final bool isVerifying;
  final bool isResending;
  final void Function(String code) onChanged;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;
  final VoidCallback? onEdit;

  const OtpVerificationQuickSheet({
    super.key,
    required this.note,
    required this.contact,
    required this.onChanged,
    this.onVerify,
    this.onResend,
    this.onEdit,
    this.verifyButtonDisabled = false,
    this.isVerifying = false,
    this.isResending = false,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).extension<AppColorsExtension>();

    final pinTheme = PinTheme(
      width: 50,
      height: 48,
      textStyle: typography.bodyLargeSemiBold,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoreTextColors.disable),
        color: colors?.pageBackground,
      ),
    );

    return OtpQuickSheetBody(
      note: note,
      contact: contact,
      verifyButtonDisabled: verifyButtonDisabled,
      isVerifying: isVerifying,
      isResending: isResending,
      onChanged: onChanged,
      onEdit: onEdit,
      onResend: onResend,
      onVerify: onVerify,
      pinTheme: pinTheme,
    );
  }
}
