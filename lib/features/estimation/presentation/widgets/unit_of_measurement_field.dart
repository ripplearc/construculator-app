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
      labelText: l10n.uomLabel,
      hintText: l10n.unitOfMeasurementHint,
      modalTitle: l10n.selectUnitTitle,
      selectedItem: selectedUnit,
      items: Unit.values.toList(),
      onItemSelected: onUnitSelected,
      isDisabled: fromCostFile,
      itemToString: (unit) => unit?.displayName ?? '',
    );
  }
}

extension UnitDisplay on Unit {
  String get displayName => switch (this) {
    Unit.pieces => 'Pieces',
    Unit.meters => 'Meters',
    Unit.squareMeters => 'Square meters',
    Unit.cubicMeters => 'Cubic meters',
    Unit.kilograms => 'Kilograms',
    Unit.tons => 'Tons',
    Unit.liters => 'Liters',
    Unit.hours => 'Hours',
    Unit.days => 'Days',
    Unit.boxes => 'Boxes',
    Unit.bags => 'Bags',
    Unit.rolls => 'Rolls',
    Unit.sheets => 'Sheets',
  };
}
