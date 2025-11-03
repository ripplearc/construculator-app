import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';


class AddEstimationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddEstimationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return CoreButton(
      variant: CoreButtonVariant.secondary,
      onPressed: onPressed,
      fullWidth: false,
      size: CoreButtonSize.medium,
      label: AppLocalizations.of(context)?.addEstimation ?? 'Add estimation',
      icon: CoreIconWidget(
        icon: CoreIcons.add,
        color: CoreIconColors.dark
      ),
    );
  }
}
