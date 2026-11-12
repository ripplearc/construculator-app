import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The grey band that opens one section of the estimate's cost list: the
/// category name on the left and the section's subtotal on the right.
///
/// The band has a light line above and below it, so it still shows on a page
/// that is the same grey. It runs the full width of the screen, scrolls with
/// the list and is never pinned. The subtotal comes from the caller, since the screen does
/// not add up lines.
class CostSectionHeader extends StatelessWidget {
  /// The category this section holds.
  final CostItemType type;

  /// The sum of the section's lines, in dollars.
  final double subtotal;

  static const _minHeight = 44.0;
  static const _nameLetterSpacing = 0.84;

  const CostSectionHeader({
    super.key,
    required this.type,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final border = BorderSide(color: colorTheme.lineLight);
    return MergeSemantics(
      child: Semantics(
        header: true,
        child: DecoratedBox(
          key: Key('cost_section_header_${type.name}'),
          decoration: BoxDecoration(
            color: colorTheme.backgroundGrayLight,
            border: Border(top: border, bottom: border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: _minHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space4,
                vertical: CoreSpacing.space2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _name(context).toUpperCase(),
                      key: Key('cost_section_name_${type.name}'),
                      style: context.textTheme.bodySmallSemiBold.copyWith(
                        color: colorTheme.textBody,
                        letterSpacing: _nameLetterSpacing,
                      ),
                    ),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        DisplayFormatter.formatCurrency(subtotal),
                        key: Key('cost_section_subtotal_${type.name}'),
                        style: context.textTheme.bodyLargeSemiBold.copyWith(
                          color: colorTheme.textHeadline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _name(BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      CostItemType.material => l10n.costSectionMaterials,
      CostItemType.labor => l10n.costSectionLabor,
      CostItemType.equipment => l10n.costSectionEquipment,
    };
  }
}
