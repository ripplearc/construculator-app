import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/uom_selector_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A tappable selector field that opens a custom bottom sheet for choosing
/// a [Unit] of measurement.

class UnitOfMeasurementField extends StatefulWidget {
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
  State<UnitOfMeasurementField> createState() => _UnitOfMeasurementFieldState();
}

class _UnitOfMeasurementFieldState extends State<UnitOfMeasurementField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(UnitOfMeasurementField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUnit != widget.selectedUnit) {
      _syncController();
    }
  }

  void _syncController() {
    final unit = widget.selectedUnit;
    final text = unit != null ? uomUnitName(context, unit) : '';
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GestureDetector(
      onTap: widget.fromCostFile ? null : () => _openSheet(context),
      child: AbsorbPointer(
        child: CoreTextField(
          label: l10n.unitOfMeasurementLabel,
          controller: _controller,
          readOnly: true,
          enabled: !widget.fromCostFile,
          suffix: CoreIconWidget(
            icon: CoreIcons.arrowDropDown,
            color: Theme.of(context).coreColors.iconGrayMid,
            size: 24,
          ),
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final unit = await UomSelectorSheet.show(
      context: context,
      selectedUnit: widget.selectedUnit,
    );
    if (unit != null) {
      widget.onUnitSelected(unit);
    }
  }
}
