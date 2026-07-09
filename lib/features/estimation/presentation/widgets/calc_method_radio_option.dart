import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CalcMethodRadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CalcMethodRadioOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoreIconWidget(
              icon: isSelected ? CoreIcons.radioChecked : CoreIcons.radio,
              color: isSelected ? colorTheme.iconDark : colorTheme.iconGrayMid,
              size: 24,
            ),
            const SizedBox(width: CoreSpacing.space2),
            Text(
              label,
              style: textTheme.bodyMediumRegular.copyWith(
                color: isSelected ? colorTheme.textHeadline : colorTheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
