import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';
enum AuthMethod {
  google,
  apple,
  microsoft,
  phone,
  email,
}
class AuthMethods extends StatelessWidget {
  const AuthMethods({super.key, required this.onPressed, this.isEmailAuth = true});
  final Function(AuthMethod) onPressed;
  final bool isEmailAuth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreButton(
          onPressed: (){
            onPressed(AuthMethod.google);
          },
          label: '${AppLocalizations.of(context)?.continueWithGoogle}',
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.google,
            size: CoreSpacing.space6,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.apple);
          },
          label: '${AppLocalizations.of(context)?.continueWithApple}',
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.apple,
            size: CoreSpacing.space6,
            color: CoreTextColors.dark,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.microsoft);
          },
          label: '${AppLocalizations.of(context)?.continueWithMicrosoft}',
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.microsoft,
            size: CoreSpacing.space6,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        if(isEmailAuth)
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.phone);
          },
          label: '${AppLocalizations.of(context)?.continueWithPhone}',
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.phone,
            size: CoreSpacing.space6,
            color: CoreTextColors.info,
          ),

          variant: CoreButtonVariant.social,
        )
        else
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.email);
          },
          icon: CoreIconWidget(
            icon: CoreIcons.email,
            size: CoreSpacing.space6,
            color: CoreTextColors.info,
          ),
          label: '${AppLocalizations.of(context)?.continueWithEmail}',
          centerAlign: true,
          spaceOut: true,
          variant: CoreButtonVariant.social,
        )
      ],
    );
  }
}
