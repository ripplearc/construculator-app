import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class SuccessModal {
  static void show(
    BuildContext context, {
    String? message,
    bool isDismissible = false,
    bool enableDrag = false,
    required VoidCallback onPressed,
    String? buttonLabel,
    String assetPath = 'assets/icons/success.png',
  }) {
    final defaultContinueText = AppLocalizations.of(context)?.continueButton;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      enableDrag: enableDrag,
      isDismissible: isDismissible,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(assetPath, width: 90, height: 90),
              const SizedBox(height: 16),
              Text(
                message ?? 'Operation Successful',
                textAlign: TextAlign.center,
                style:
                    CoreTypography.titleLargeMedium(), // Use your own style here
              ),
              const SizedBox(height: 24),
              CoreButton(
                onPressed: onPressed,
                label: buttonLabel ?? (defaultContinueText ?? 'Continue'),
                centerAlign: true,
              ),
            ],
          ),
        );
      },
    );
  }
}
