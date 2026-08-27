import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

enum _UomMode { fromList, manually }

const _unitsByCategory = [
  [Unit.meters],
  [Unit.squareMeters, Unit.sheets],
  [Unit.cubicMeters, Unit.liters, Unit.bags],
  [Unit.kilograms, Unit.tons],
  [Unit.pieces, Unit.boxes, Unit.rolls],
  [Unit.hours, Unit.days],
];

String uomUnitName(BuildContext context, Unit unit) {
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

class UomSelectorSheet extends StatefulWidget {
  final Unit? selectedUnit;

  const UomSelectorSheet({super.key, this.selectedUnit});

  static Future<Unit?> show({
    required BuildContext context,
    Unit? selectedUnit,
  }) {
    return CoreQuickSheet.show<Unit?>(
      context: context,
      useSafeArea: true,
      child: UomSelectorSheet(selectedUnit: selectedUnit),
    );
  }

  @override
  State<UomSelectorSheet> createState() => _UomSelectorSheetState();
}

class _UomSelectorSheetState extends State<UomSelectorSheet> {
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
            onTap: () => Navigator.of(context).pop(unit),
            child: Padding(
              padding: const EdgeInsets.all(CoreSpacing.space3),
              child: Text(
                uomUnitName(context, unit),
                style: typography.bodyMediumRegular.copyWith(
                  color: colors.textHeadline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeCard(AppLocalizations l10n) {
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
