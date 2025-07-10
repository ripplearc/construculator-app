import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.text,
    required this.actionText,
    required this.onPressed,
  });
  final String text;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: CoreSpacing.space16,
        margin: EdgeInsets.only(bottom: CoreSpacing.space8),
        width: double.infinity,
        color: CoreBackgroundColors.backgroundBlueLight,
        child: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('$text ', style: CoreTypography.bodyMediumRegular()),
              InkWell(
                onTap: onPressed,
                key: Key('auth_footer_link'),
                child: Text(
                  actionText,
                  style: CoreTypography.bodyMediumSemiBold(
                    color: CoreTextColors.link,
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
