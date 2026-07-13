import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class UnitOfMeasurementField extends StatelessWidget {
  final bool fromCostFile;
  final Unit? selectedUnit;
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
    return SingleItemSelector<Unit>(
      hintText: l10n.unitOfMeasurementHint,
      modalTitle: l10n.selectUnitTitle,
      selectedItem: selectedUnit,
      items: Unit.values.toList(),
      onItemSelected: onUnitSelected,
      isDisabled: fromCostFile,
      itemToString: (unit) => switch (unit) {
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
        null => '',
      },
    );
  }
}
