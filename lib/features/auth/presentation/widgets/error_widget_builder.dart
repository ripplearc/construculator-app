import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:flutter/material.dart';

/// Displays an error message and a link, useful for displaying errors on the login and register pages
/// With an embedded link for quick navigation to the appropriate page
/// [errorText] - The error message to display
/// [linkText] - The text of the link to display
/// [onPressed] - The callback to be called when the link is pressed
Widget buildErrorWidgetWithLink({
  required BuildContext context,
  String? errorText,
  String? linkText,
  required VoidCallback onPressed,
}) {
  final typography = Theme.of(context).extension<TypographyExtension>();

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          errorText ?? '',
          style: typography?.bodySmallRegular.copyWith(
            color: CoreTextColors.error,
          ),
        ),
      ),
      if (linkText != null)
        GestureDetector(
          onTap: onPressed,
          key: Key(linkText),
          child: Text(
            linkText,
            style: typography?.bodySmallSemiBold.copyWith(
              color: CoreTextColors.link,
            ),
          ),
        ),
    ],
  );
}
