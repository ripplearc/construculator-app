import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

class TermsAndConditionsSection extends StatelessWidget {
  const TermsAndConditionsSection({
    super.key,
    required this.termsAndConditionsText,
    required this.termsAndServicesLink,
    required this.privacyPolicyLink,
    required this.andAcknowledge,
    required this.onTermsAndConditionsLinkPressed,
    required this.onPrivacyPolicyLinkPressed,
  });
  final String termsAndConditionsText;
  final String termsAndServicesLink;
  final String privacyPolicyLink;
  final String andAcknowledge;
  final VoidCallback onTermsAndConditionsLinkPressed;
  final VoidCallback onPrivacyPolicyLinkPressed;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).coreTypography;

    return Text.rich(
      TextSpan(
        text: termsAndConditionsText,
        style: typography.bodyMediumRegular.copyWith(
          color: CoreTextColors.headline,
        ),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: onTermsAndConditionsLinkPressed,
              child: Text(
                termsAndServicesLink,
                style: typography.bodyMediumMedium.copyWith(
                  color: CoreTextColors.link,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          TextSpan(text: ' $andAcknowledge '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyPolicyLinkPressed,
              child: Text(
                privacyPolicyLink,
                style: typography.bodyMediumMedium.copyWith(
                  color: CoreTextColors.link,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
