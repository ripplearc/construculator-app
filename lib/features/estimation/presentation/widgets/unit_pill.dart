import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/select_unit_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The rounded unit button next to the quantity, showing the unit's symbol.
/// Tapping it opens the Select unit sheet; the unit is never typed.
class UnitPill extends StatelessWidget {
  static const double _pillHeight = CoreSpacing.space8;
  static const double _tapHeight = CoreSpacing.space12;

  /// The picked unit, or null while none is picked.
  final Unit? unit;

  /// Called with the unit the user picked from the list.
  final ValueChanged<Unit> onUnitSelected;

  /// Whether tapping opens the list. False while the line is being saved.
  final bool isEnabled;

  const UnitPill({
    super.key,
    required this.unit,
    required this.onUnitSelected,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final l10n = context.l10n;
    final unit = this.unit;
    return SizedBox(
      height: _pillHeight,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        fit: OverflowBoxFit.deferToChild,
        minHeight: _tapHeight,
        maxHeight: _tapHeight,
        child: Semantics(
          button: true,
          label: unit == null
              ? l10n.unitPillEmptySemanticLabel
              : l10n.unitPillSemanticLabel(unit.displayName(l10n)),
          excludeSemantics: true,
          enabled: isEnabled,
          onTap: isEnabled ? () => _openList(context) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openList(context),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: Container(
                height: _pillHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CoreSpacing.space5),
                  border: Border.all(color: colorTheme.lineMid),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: CoreSpacing.space1,
                  children: [
                    Text(
                      unit == null
                          ? l10n.unitPillEmptyLabel
                          : unit.symbol(l10n),
                      style: textTheme.bodyLargeRegular.copyWith(
                        color: unit == null
                            ? colorTheme.textDisable
                            : colorTheme.textHeadline,
                      ),
                    ),
                    CoreIconWidget(
                      icon: CoreIcons.arrowDown,
                      size: CoreIconSize.size20,
                      color: colorTheme.iconGrayMid,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openList(BuildContext context) async {
    if (!isEnabled) return;
    final picked = await CoreQuickSheet.show<Unit>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: SelectUnitSheet(groups: imperialMaterialUnits, selected: unit),
    );
    if (picked != null) onUnitSelected(picked);
  }
}
