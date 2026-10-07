import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The rounded unit button next to the quantity. Tapping it opens the unit
/// list; the unit is never typed.
///
// TODO: [CA-1186] replace the interim 13-unit list with the grouped 23-unit "Select unit" sheet. https://ripplearc.youtrack.cloud/issue/CA-1186
class UnitPill extends StatelessWidget {
  static const double _tapPadding = 5;

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
    return Semantics(
      button: true,
      label: unit == null
          ? l10n.unitPillEmptySemanticLabel
          : l10n.unitPillSemanticLabel(unit.displayName(l10n)),
      // The label already says what the button shows and does, so the text
      // and icon inside would be read a second time.
      excludeSemantics: true,
      onTap: () => _openList(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openList(context),
        child: Padding(
          // Makes the tap area 48 dp tall while the drawn pill stays 38 dp.
          padding: const EdgeInsets.symmetric(vertical: _tapPadding),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space3,
              vertical: CoreSpacing.space2 - 2,
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
                      : unit.displayName(l10n),
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
    );
  }

  Future<void> _openList(BuildContext context) async {
    if (!isEnabled) return;
    final picked = await CoreQuickSheet.show<Unit>(
      context: context,
      backgroundColor: sheetSurface(context),
      child: _UnitList(selected: unit),
    );
    if (picked != null) onUnitSelected(picked);
  }
}

class _UnitList extends StatelessWidget {
  final Unit? selected;

  const _UnitList({required this.selected});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = context.textTheme;
    final colorTheme = context.colorTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(CoreSpacing.space4),
            child: Text(
              l10n.selectUnitTitle,
              style: textTheme.titleMediumSemiBold.copyWith(
                color: colorTheme.textHeadline,
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final unit in Unit.values)
                    CoreCheckRowItem(
                      key: Key('unit_option_${unit.name}'),
                      title: unit.displayName(l10n),
                      selected: unit == selected,
                      onChanged: (_) => Navigator.of(context).pop(unit),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
