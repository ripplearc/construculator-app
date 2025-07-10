import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

Widget buildErrorWidget({
  String? errorText,
  String? linkText,
  required VoidCallback onPressed,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          errorText ?? '',
          style: CoreTypography.bodySmallRegular(color: CoreTextColors.error),
        ),
      ),
      if (linkText != null)
        InkWell(
          onTap: onPressed,
          key: Key(linkText),
          child: Text(
            linkText,
            style: CoreTypography.bodySmallSemiBold(color: CoreTextColors.link),
          ),
        ),
    ],
  );
}
