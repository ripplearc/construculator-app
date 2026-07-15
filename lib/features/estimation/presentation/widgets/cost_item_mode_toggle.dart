import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: [CA-???] Replace with a compact variant of CoreSelectButton once available.
/// Two-pill segmented toggle for selecting between "From cost file" and "Manually" modes.
class CostItemModeToggle extends StatelessWidget {
  /// Whether the "From cost file" pill is active; false means "Manually" is active.
  final bool fromCostFile;

  /// Called when the user taps the "From cost file" pill while it is not already active.
  final VoidCallback onFromCostFile;

  /// Called when the user taps the "Manually" pill while it is not already active.
  final VoidCallback onManually;

  const CostItemModeToggle({
    super.key,
    required this.fromCostFile,
    required this.onFromCostFile,
    required this.onManually,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final l10n = context.l10n;
    return Container(
      key: const Key('mode_toggle_container'),
      padding: const EdgeInsets.all(CoreSpacing.space1),
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.circular(CoreSpacing.space12),
        boxShadow: [BoxShadow(color: colorTheme.shadowGrey10, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPill(
              context,
              key: const Key('from_cost_file_pill'),
              label: l10n.fromCostFileMode,
              semanticLabel: l10n.fromCostFileModeSemanticLabel,
              isActive: fromCostFile,
              onTap: onFromCostFile,
            ),
          ),
          const SizedBox(width: CoreSpacing.space1 / 2),
          Expanded(
            child: _buildPill(
              context,
              key: const Key('manually_pill'),
              label: l10n.manuallyMode,
              semanticLabel: l10n.manuallyModeSemanticLabel,
              isActive: !fromCostFile,
              onTap: onManually,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context, {
    required Key key,
    required String label,
    required String semanticLabel,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      key: key,
      label: semanticLabel,
      selected: isActive,
      button: true,
      child: GestureDetector(
        onTap: isActive ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(
            vertical: CoreSpacing.space3 / 2,
            horizontal: CoreSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: isActive ? colorTheme.tabsHighlight : colorTheme.transparent,
            borderRadius: BorderRadius.circular(CoreSpacing.space4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colorTheme.shadowGrey10,
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: isActive
                ? textTheme.bodyMediumSemiBold.copyWith(
                    color: colorTheme.textHeadline,
                  )
                : textTheme.bodyMediumRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
          ),
        ),
      ),
    );
  }
}
