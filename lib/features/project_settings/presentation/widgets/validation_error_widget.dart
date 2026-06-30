import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays a single field validation error with an error icon and red text.
///
/// Matches the internal error layout used by [CoreTextField] so that fields
/// which cannot use [CoreTextField] (e.g. multi-line [TextFormField]) render
/// errors consistently.
class ValidationErrorWidget extends StatelessWidget {
  const ValidationErrorWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreIconWidget(
          icon: CoreIcons.error,
          size: CoreIconSize.size16,
          color: colors.iconRed,
        ),
        const SizedBox(width: CoreSpacing.space1),
        Expanded(
          child: Text(
            message,
            style: typography.bodySmallRegular.copyWith(color: colors.textError),
          ),
        ),
      ],
    );
  }
}
