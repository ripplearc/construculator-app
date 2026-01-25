import 'package:ripplearc_coreui/ripplearc_coreui.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';

/// A widget that displays a footer with a text and an action text
/// Meant to be resused on login and register pages
class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.text,
    required this.actionText,
    required this.onPressed,
  });

  /// The text to display
  final String text;

  /// The text of the action to display
  final String actionText;

  /// The callback to be called when the action is pressed
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).coreTypography;
    final colors = context.colorTheme;

    return SafeArea(
      child: Container(
        height: CoreSpacing.space16,
        width: double.infinity,
        color: colors.backgroundBlueLight,
        child: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$text ', style: typography.bodyMediumRegular),
              InkWell(
                onTap: onPressed,
                key: Key('auth_footer_link'),
                child: Text(
                  actionText,
                  style: typography.bodyMediumSemiBold.copyWith(
                    color: colors.textLink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
