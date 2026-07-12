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
      child: const _UomSelectorSheet(),
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

class _UomSelectorSheet extends StatefulWidget {
  const _UomSelectorSheet();

  @override
  State<_UomSelectorSheet> createState() => _UomSelectorSheetState();
}

class _UomSelectorSheetState extends State<_UomSelectorSheet> {
  _UomMode _mode = _UomMode.fromList;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = Theme.of(context).coreTypography;
    final colors = Theme.of(context).coreColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CoreSpacing.space4,
            CoreSpacing.space3,
            CoreSpacing.space4,
            CoreSpacing.space3,
          ),
          child: Text(
            l10n.uomSheetTitle,
            style: typography.headlineMediumSemiBold,
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildModeCard(l10n, typography, colors),
              if (_mode == _UomMode.manually) ...[
                const SizedBox(height: CoreSpacing.space4),
                CoreTextField(hintText: l10n.uomManualInputHint),
              ],
            ],
          ),
        ),
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

  Widget _buildModeCard(dynamic l10n, dynamic typography, dynamic colors) {
    return Container(
      padding: const EdgeInsets.all(CoreSpacing.space3),
      decoration: BoxDecoration(
        color: colors.pageBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: CoreShadows.medium,
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
                  typography: typography,
                  colors: colors,
                ),
              ),
              const SizedBox(width: CoreSpacing.space8),
              Flexible(
                child: _buildRadioOption(
                  label: l10n.uomManuallyOption,
                  value: _UomMode.manually,
                  typography: typography,
                  colors: colors,
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
    required dynamic typography,
    required dynamic colors,
  }) {
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
