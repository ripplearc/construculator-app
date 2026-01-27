// coverage:ignore-file
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpQuickSheetBody extends StatelessWidget {
  const OtpQuickSheetBody({
    super.key,
    required this.note,
    required this.contact,
    required this.verifyButtonDisabled,
    required this.isVerifying,
    required this.isResending,
    required this.onChanged,
    required this.onEdit,
    required this.onResend,
    required this.onVerify,
    required this.pinTheme,
  });

  final String note;
  final String contact;
  final bool verifyButtonDisabled;
  final bool isVerifying;
  final bool isResending;
  final Function(String) onChanged;
  final VoidCallback? onEdit;
  final VoidCallback? onResend;
  final VoidCallback? onVerify;
  final PinTheme pinTheme;

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final colors = context.colorTheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(CoreSpacing.space6),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: CoreSpacing.space2),
            Center(
              child: Container(
                width: CoreSpacing.space10,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: colors.textDisable,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CoreSpacing.space6),
            Text(
              context.l10n.authenticationCodeTitle,
              style: typography.headlineMediumSemiBold,
            ),
            const SizedBox(height: CoreSpacing.space2),
            RichText(
              text: TextSpan(
                style: typography.bodyLargeRegular.copyWith(
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
                children: [
                  TextSpan(text: note, style: typography.bodyLargeRegular),
                  WidgetSpan(
                    child: GestureDetector(
                      key: Key('edit_contact_button'),
                      onTap: onEdit,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 4),
                          Text(
                            contact,
                            style: typography.bodyLargeSemiBold.copyWith(
                              color: colors.textLink,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colors.textLink,
                          ),
                        ],
                      ),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Pinput(
              key: const Key('pin_input'),
              length: 6,
              defaultPinTheme: pinTheme,
              focusedPinTheme: pinTheme.copyWith(
                decoration: pinTheme.decoration?.copyWith(
                  border: Border.all(color: colors.buttonSurface),
                ),
              ),
              onChanged: (value) {
                onChanged(value);
              },
            ),
            const SizedBox(height: CoreSpacing.space4),
            Text.rich(
              TextSpan(
                text: '${context.l10n.didNotReceiveCode} ',
                style: typography.bodyMediumRegular.copyWith(
                  color: colors.textDark,
                ),

                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onResend,
                      child: Text(
                        isResending
                            ? context.l10n.resendingButtonLabel
                            : context.l10n.resendButton,
                        style: typography.bodyMediumSemiBold.copyWith(
                          color: colors.textLink,
                        ),
                      ),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: CoreSpacing.space6),
            CoreButton(
              onPressed: onVerify,
              label: isVerifying
                  ? context.l10n.verifyingButtonLabel
                  : context.l10n.verifyOtpButton,
              isDisabled: verifyButtonDisabled,
              spaceOut: true,
              trailing: true,
              icon: CoreIconWidget(
                icon: CoreIcons.checkCircle,
                size: 24,
                color: verifyButtonDisabled
                    ? colors.textBody
                    : colors.textInverse,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
