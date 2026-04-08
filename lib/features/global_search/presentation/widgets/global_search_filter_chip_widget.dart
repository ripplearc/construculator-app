import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A dropdown-style filter chip used in the [GlobalSearchPage] filter row.
///
/// Renders as an outlined pill with a label and trailing dropdown arrow,
/// matching the Figma design for the Global Search filter row.
class GlobalSearchFilterChipWidget extends StatelessWidget {
  const GlobalSearchFilterChipWidget({
    super.key,
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final isEnabled = onTap != null;

    return Semantics(
      label: label,
      button: isEnabled,
      enabled: isEnabled,
      child: GestureDetector(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: CoreSpacing.space12,
            minWidth: CoreSpacing.space12,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space4,
              vertical: CoreSpacing.space2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CoreSpacing.space3),
              color: colors.lineLight,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: typography.bodyMediumRegular.copyWith(
                    color: colors.textDark,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space2),
                CoreIconWidget(
                  icon: CoreIcons.arrowDropDown,
                  color: colors.textDark,
                  size: CoreSpacing.space4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
