import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The terms and privacy links shown on the consent gate.
///
/// Reuses the visual treatment of the signup screen's terms section so the two
/// places we ask for the same agreement look the same.
///
/// Each link is wrapped to a 48dp minimum tap target rather than relying on
/// text bounds — underlined body text is well under the guideline on its own,
/// and these are the only way to read what is being agreed to.
class ConsentDocumentLinks extends StatelessWidget {
  /// Label for the terms of service link.
  final String termsLabel;

  /// Label for the privacy policy link.
  final String privacyLabel;

  /// Opens the terms of service document.
  final VoidCallback onTermsPressed;

  /// Opens the privacy policy document.
  final VoidCallback onPrivacyPressed;

  const ConsentDocumentLinks({
    super.key,
    required this.termsLabel,
    required this.privacyLabel,
    required this.onTermsPressed,
    required this.onPrivacyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CoreSpacing.space4,
      runSpacing: CoreSpacing.space2,
      children: [
        _DocumentLink(
          key: const Key('consentGateTermsLink'),
          label: termsLabel,
          onPressed: onTermsPressed,
        ),
        _DocumentLink(
          key: const Key('consentGatePrivacyLink'),
          label: privacyLabel,
          onPressed: onPrivacyPressed,
        ),
      ],
    );
  }
}

class _DocumentLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DocumentLink({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final colors = context.colorTheme;

    return Semantics(
      link: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: typography.bodyMediumMedium.copyWith(
                color: colors.textLink,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
