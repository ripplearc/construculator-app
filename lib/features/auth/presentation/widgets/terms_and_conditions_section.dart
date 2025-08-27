import 'package:core_ui/core_ui.dart';
import 'package:flutter/widgets.dart';

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
    return Text.rich(
      TextSpan(
        text: termsAndConditionsText,
        style: CoreTypography.bodyMediumRegular(color: CoreTextColors.headline),
        children: [
          WidgetSpan(
            child: GestureDetector(
              onTap: onTermsAndConditionsLinkPressed,
              child: Text(
                termsAndServicesLink,
                style: CoreTypography.bodyMediumMedium(
                  color: CoreTextColors.link,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
          TextSpan(text: ' $andAcknowledge '),
          WidgetSpan(
            child: GestureDetector(
              onTap: onPrivacyPolicyLinkPressed,
              child: Text(
                privacyPolicyLink,
                style: CoreTypography.bodyMediumMedium(
                  color: CoreTextColors.link,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
