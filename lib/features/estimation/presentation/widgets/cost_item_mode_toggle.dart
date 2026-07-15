import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: [CA-???] Remove once CoreSelectButton supports compact sizing (6px pill padding / 2px gap).
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
    final l10n = context.l10n;
    return CoreSelectButton(
      tabs: [l10n.fromCostFileMode, l10n.manuallyMode],
      selectedIndex: fromCostFile ? 0 : 1,
      onChanged: (index) => index == 0 ? onFromCostFile() : onManually(),
    );
  }
}
