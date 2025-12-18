import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

class ForgotPasswordHeader extends StatelessWidget {
  final String title;
  final String description;
  const ForgotPasswordHeader({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<TypographyExtension>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: typography?.headlineLargeSemiBold),
        const SizedBox(height: CoreSpacing.space2),
        Text(description, style: typography?.bodyLargeRegular),
      ],
    );
  }
}
