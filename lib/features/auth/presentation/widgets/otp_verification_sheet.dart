import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:core_ui/core_ui.dart'; // Assuming you have core_ui for styles

class OtpVerificationBottomSheet extends StatelessWidget {
  final String note;
  final String contact;
  final bool verifyButtonDisabled;
  final bool isVerifying;
  final bool isResending;
  final void Function(String code) onChanged;
  final VoidCallback? onVerify;
  final VoidCallback? onResend;
  final VoidCallback? onEdit;

  const OtpVerificationBottomSheet({
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
    final pinTheme = PinTheme(
      width: 50,
      height: 48,
      textStyle: CoreTypography.bodyLargeSemiBold(),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CoreTextColors.disable),
        color: CoreBackgroundColors.pageBackground,
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: CoreBackgroundColors.pageBackground,
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
                  color: CoreTextColors.disable,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: CoreSpacing.space6),
            Text(
              '${AppLocalizations.of(context)?.authenticationCode}',
              style: CoreTypography.headlineMediumSemiBold(),
            ),
            const SizedBox(height: CoreSpacing.space2),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
                children: [
                  TextSpan(
                    text: note,
                    style: CoreTypography.bodyLargeRegular(),
                  ),
                  WidgetSpan(
                    child: InkWell(
                      key: Key('edit_contact_button'),
                      onTap: onEdit,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 4,),
                          Text(
                            contact,
                            style: CoreTypography.bodyLargeSemiBold(
                              color: CoreTextColors.link,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: CoreTextColors.link,
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
                  border: Border.all(color: CoreButtonColors.surface),
                ),
              ),
              onChanged: (value) {
                onChanged(value);
              },
            ),
            const SizedBox(height: CoreSpacing.space4),
            Text.rich(
              TextSpan(
                text: '${AppLocalizations.of(context)?.didNotReceiveCode} ',
                style: TextStyle(color: CoreTextColors.dark),

                children: [
                  WidgetSpan(
                    child: InkWell(
                      onTap: onResend,
                      child: Text(
                        isResending
                            ? '${AppLocalizations.of(context)?.resendingButtonLabel}'
                            : '${AppLocalizations.of(context)?.resendButton}',
                        style: TextStyle(
                          color: CoreTextColors.link,
                          fontWeight: FontWeight.bold,
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
              label:
                  isVerifying
                      ? '${AppLocalizations.of(context)?.verifyingButtonLabel}'
                      : '${AppLocalizations.of(context)?.verifyButtonLabel}',
              isDisabled: verifyButtonDisabled,
              spaceOut: true,
              trailing: true,
              icon: CoreIconWidget(
                icon: CoreIcons.checkCircle,
                size: 24,
                color:
                    verifyButtonDisabled
                        ? CoreTextColors.body
                        : CoreTextColors.inverse,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
