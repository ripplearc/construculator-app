// coverage:ignore-file
import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
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
    final typography = Theme.of(context).coreTypography;
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
              '${AppLocalizations.of(context)?.authenticationCodeTitle}',
              style: typography.headlineMediumSemiBold,
            ),
            const SizedBox(height: CoreSpacing.space2),
            RichText(
              text: TextSpan(
                style: typography.bodyLargeRegular.copyWith(
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
                children: [
                  TextSpan(
                    text: note,
                    style: typography.bodyLargeRegular,
                  ),
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
                style: typography.bodyMediumRegular.copyWith(
                  color: CoreTextColors.dark,
                ),

                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: onResend,
                      child: Text(
                        isResending
                            ? '${AppLocalizations.of(context)?.resendingButtonLabel}'
                            : '${AppLocalizations.of(context)?.resendButton}',
                        style: typography.bodyMediumSemiBold.copyWith(
                          color: CoreTextColors.link,
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
                  ? '${AppLocalizations.of(context)?.verifyingButtonLabel}'
                  : '${AppLocalizations.of(context)?.verifyOtpButton}',
              isDisabled: verifyButtonDisabled,
              spaceOut: true,
              trailing: true,
              icon: CoreIconWidget(
                icon: CoreIcons.checkCircle,
                size: 24,
                color: verifyButtonDisabled
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
