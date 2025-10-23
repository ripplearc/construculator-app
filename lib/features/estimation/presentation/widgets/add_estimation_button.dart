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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: CoreBorderColors.outlineFocus,
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoreIconWidget(
              icon: CoreIconData.svg('assets/icons/plus_icon.svg'),
              size: 14,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)?.addEstimation ?? 'Add estimation',
              style: TextStyle(
                color: CoreBorderColors.outlineFocus,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
