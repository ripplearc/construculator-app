import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/ui/core_icon_sizes.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Enum for the different auth methods
/// [google] - Google auth
/// [apple] - Apple auth
/// [microsoft] - Microsoft auth
/// [phone] - Phone auth
/// [email] - Email auth
enum AuthMethod { google, apple, microsoft, phone, email }

/// A widget that displays the auth provider buttons
class AuthProviderButtons extends StatelessWidget {
  /// Constructor for the AuthProviderButtons widget
  const AuthProviderButtons({
    super.key,
    required this.onPressed,
    this.isEmailAuth = true,
  });

  /// The callback to be called when the button is pressed
  final Function(AuthMethod) onPressed;

  /// Whether the auth is email auth or phone auth, if true, renders the phone auth button,
  /// otherwise renders the email auth button
  final bool isEmailAuth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;

    return Column(
      children: [
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.google);
          },
          label: context.l10n.continueWithGoogle,
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.google,
            size: CoreIconSizes.medium,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.apple);
          },
          label: context.l10n.continueWithApple,
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.apple,
            size: CoreIconSizes.medium,
            color: colors.textDark,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        CoreButton(
          onPressed: () {
            onPressed(AuthMethod.microsoft);
          },
          label: context.l10n.continueWithMicrosoft,
          centerAlign: true,
          spaceOut: true,
          icon: CoreIconWidget(
            icon: CoreIcons.microsoft,
            size: CoreIconSizes.medium,
          ),
          variant: CoreButtonVariant.social,
        ),
        const SizedBox(height: CoreSpacing.space4),
        if (isEmailAuth)
          CoreButton(
            onPressed: () {
              onPressed(AuthMethod.phone);
            },
            label: context.l10n.continueWithPhone,
            centerAlign: true,
            spaceOut: true,
            icon: CoreIconWidget(
              icon: CoreIcons.phone,
              size: CoreIconSizes.medium,
              color: colors.textInfo,
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
              size: CoreIconSizes.medium,
              color: colors.textInfo,
            ),
            label: context.l10n.continueWithEmail,
            centerAlign: true,
            spaceOut: true,
            variant: CoreButtonVariant.social,
          ),
      ],
    );
  }
}
