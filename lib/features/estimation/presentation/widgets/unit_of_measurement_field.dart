import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

enum _UomMode { fromList, manually }

/// A tappable selector field that opens a custom bottom sheet for choosing
/// a [Unit] of measurement.

class UnitOfMeasurementField extends StatelessWidget {
  /// When `true`, the field is read-only (unit is pre-filled from a cost file).
  final bool fromCostFile;

  /// The currently selected unit, or `null` when no unit has been chosen.
  final Unit? selectedUnit;

  /// Called with the chosen [Unit] when the user makes a selection.
  final ValueChanged<Unit?> onUnitSelected;

  const UnitOfMeasurementField({
    super.key,
    required this.fromCostFile,
    required this.selectedUnit,
    required this.onUnitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).coreColors;
    final unit = selectedUnit;
    final displayText = unit != null
        ? _resolveUnitName(context, unit)
        : l10n.unitOfMeasurementHint;

    return InkWell(
      onTap: fromCostFile ? null : () => _openSheet(context),
      child: InputDecorator(
        // No labelText per Figma spec — the hint doubles as the field label for
        // this selector (unlike the text inputs alongside it).
        decoration: InputDecoration(
          hintText: l10n.unitOfMeasurementHint,
          enabled: !fromCostFile,
          hintStyle: typography.bodyLargeSemiBold.copyWith(
            color: fromCostFile ? colors.textDisable : colors.outlineFocus,
          ),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: typography.bodyLargeRegular.copyWith(
                  color: (selectedUnit == null || fromCostFile)
                      ? Theme.of(context).hintColor
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    CoreQuickSheet.show(
      context: context,
      useSafeArea: true,
      child: _UomSelectorSheet(
        selectedUnit: selectedUnit,
        onUnitSelected: (unit) {
          Navigator.of(context).pop();
          onUnitSelected(unit);
        },
      ),
    );
  }
}

String _resolveUnitName(BuildContext context, Unit unit) {
  final l10n = context.l10n;
  return switch (unit) {
    Unit.pieces => l10n.unitPieces,
    Unit.meters => l10n.unitMeters,
    Unit.squareMeters => l10n.unitSquareMeters,
    Unit.cubicMeters => l10n.unitCubicMeters,
    Unit.kilograms => l10n.unitKilograms,
    Unit.tons => l10n.unitTons,
    Unit.liters => l10n.unitLiters,
    Unit.hours => l10n.unitHours,
    Unit.days => l10n.unitDays,
    Unit.boxes => l10n.unitBoxes,
    Unit.bags => l10n.unitBags,
    Unit.rolls => l10n.unitRolls,
    Unit.sheets => l10n.unitSheets,
  };
}

const _unitsByCategory = [
  [Unit.meters],                              // Length
  [Unit.squareMeters, Unit.sheets],           // Area
  [Unit.cubicMeters, Unit.liters, Unit.bags], // Volume
  [Unit.kilograms, Unit.tons],               // Weight
  [Unit.pieces, Unit.boxes, Unit.rolls],     // Count
  [Unit.hours, Unit.days],                   // Time
];

class _UomSelectorSheet extends StatefulWidget {
  final Unit? selectedUnit;
  final ValueChanged<Unit?> onUnitSelected;

  const _UomSelectorSheet({
    required this.onUnitSelected,
    this.selectedUnit,
  });

  @override
  State<_UomSelectorSheet> createState() => _UomSelectorSheetState();
}

class _UomSelectorSheetState extends State<_UomSelectorSheet> {
  _UomMode _mode = _UomMode.fromList;
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = Theme.of(context).coreTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
            CoreSpacing.space4,
            CoreSpacing.space3,
            CoreSpacing.space4,
            CoreSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).coreColors.pageBackground,
            boxShadow: CoreShadows.small,
          ),
          child: Text(
            l10n.uomSheetTitle,
            style: typography.headlineMediumSemiBold,
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          child: _buildModeCard(l10n),
        ),
        const SizedBox(height: CoreSpacing.space2),
        if (_mode == _UomMode.fromList) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: CoreTabs(
              tabs: [
                l10n.uomCategoryLength,
                l10n.uomCategoryArea,
                l10n.uomCategoryVolume,
                l10n.uomCategoryWeight,
                l10n.uomCategoryCount,
                l10n.uomCategoryTime,
              ],
              selectedIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
            ),
          ),
          const SizedBox(height: CoreSpacing.space2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: _buildUnitList(),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
            child: CoreTextField(hintText: l10n.uomManualInputHint),
          ),
        ],
        const SizedBox(height: CoreSpacing.space6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          child: CoreButton(
            label: l10n.addUomButton,
            isDisabled: true,
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
      ],
    );
  }

  Widget _buildUnitList() {
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).coreColors;
    final units = _unitsByCategory[_tabIndex];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final unit in units)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Navigator.of(context).pop();
              widget.onUnitSelected(unit);
            },
            child: Padding(
              padding: const EdgeInsets.all(CoreSpacing.space3),
              child: Text(
                _resolveUnitName(context, unit),
                style: typography.bodyMediumRegular.copyWith(
                  color: colors.textHeadline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeCard(dynamic l10n) {
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).coreColors;

    return Container(
      padding: const EdgeInsets.all(CoreSpacing.space3),
      decoration: BoxDecoration(
        color: colors.pageBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: CoreShadows.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.uomAddModeQuestion,
            style: typography.bodyMediumRegular.copyWith(
              color: colors.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space3),
          Row(
            children: [
              Flexible(
                child: _buildRadioOption(
                  label: l10n.uomFromListOption,
                  value: _UomMode.fromList,
                ),
              ),
              const SizedBox(width: CoreSpacing.space8),
              Flexible(
                child: _buildRadioOption(
                  label: l10n.uomManuallyOption,
                  value: _UomMode.manually,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required _UomMode value,
  }) {
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).coreColors;
    final isSelected = _mode == value;

    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<_UomMode>(
              value: value,
              groupValue: _mode,
              onChanged: (v) {
                if (v != null) setState(() => _mode = v);
              },
              activeColor: colors.outlineFocus,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: CoreSpacing.space2),
          Flexible(
            child: Text(
              label,
              style: typography.bodyMediumRegular.copyWith(
                color: isSelected ? colors.textHeadline : colors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
