import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Form fields for adding an equipment cost item.
class EquipmentCostFormFields extends StatefulWidget {
  /// When true, renders fields for selecting from a cost file; otherwise renders manual-entry fields.
  final bool fromCostFile;
  final ValueChanged<double>? onTotalChanged;
  final ValueChanged<bool>? onSaveEnabledChanged;

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
  });

  @override
  State<EquipmentCostFormFields> createState() =>
      _EquipmentCostFormFieldsState();
}

class _EquipmentCostFormFieldsState extends State<EquipmentCostFormFields> {
  final _equipmentNameController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _equipmentNameController.addListener(_notifySaveEnabled);
    _unitPriceController.addListener(_notifyTotal);
    _quantityController.addListener(_notifyTotal);
  }

  @override
  void didUpdateWidget(covariant EquipmentCostFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCostFile != widget.fromCostFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyTotal();
        _notifySaveEnabled();
      });
    }
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _unitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // TODO: [CA-800] Fold into shared mixin/base alongside _notifyTotal https://ripplearc.youtrack.cloud/issue/CA-800
  void _notifySaveEnabled() {
    if (widget.fromCostFile) {
      widget.onSaveEnabledChanged?.call(false);
      return;
    }
    final value = _equipmentNameController.text;
    widget.onSaveEnabledChanged?.call(value.trim().isNotEmpty);
    context
        .read<EquipmentCostFormBloc>()
        .add(EquipmentCostItemTypeChanged(value));
  }

  // TODO: [CA-353] Move total calculation into BLoC when submission is wired
  void _notifyTotal() {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final rawPrice = double.tryParse(_unitPriceController.text) ?? 0;
    final rawQty = double.tryParse(_quantityController.text) ?? 0;
    final price = rawPrice.isFinite ? rawPrice : 0.0;
    final qty = rawQty.isFinite ? rawQty : 0.0;
    widget.onTotalChanged?.call(price * qty);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.fromCostFile)
            ..._fromCostFileFields(context)
          else
            ..._manuallyFields(context),
          const SizedBox(height: CoreSpacing.space6),
          // TODO: [CA-336] Add assign task section
          // TODO: [CA-349] Build Preview Cost File UI (fromCostFile mode only)
        ],
      ),
    );
  }

  List<Widget> _fromCostFileFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      // TODO: [CA-298] Wire cost file dropdown to CostFileDataSource
      CoreTextField(
        key: const Key('cost_file_field'),
        hintText: l10n.costFilePlaceholder,
        readOnly: true,
        enabled: false,
        suffix: CoreIconWidget(
          icon: CoreIcons.arrowDropDown,
          color: colorTheme.iconGrayMid,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      // TODO: [CA-298] Populate equipment type from selected cost file
      CoreTextField(
        key: const Key('equipment_type_field'),
        hintText: l10n.equipmentTypeLabel,
        readOnly: true,
        enabled: false,
        suffix: CoreIconWidget(
          icon: CoreIcons.arrowDropDown,
          color: colorTheme.iconGrayMid,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('quantity_field'),
        label: l10n.quantityLabel,
        controller: _quantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  List<Widget> _manuallyFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      BlocBuilder<EquipmentCostFormBloc, EquipmentCostFormState>(
        builder: (_, state) {
          final error =
              state is EquipmentCostFormEditing ? state.itemTypeError : null;
          return CoreTextField(
            key: const Key('equipment_name_field'),
            hintText: l10n.equipmentNameLabel,
            controller: _equipmentNameController,
            errorTextList:
                error != null ? [l10n.equipmentNameRequiredError] : null,
          );
        },
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('unit_price_field'),
        label: l10n.unitPriceLabel,
        controller: _unitPriceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: CoreIconWidget(
          icon: CoreIcons.dollar,
          color: colorTheme.textHeadline,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('quantity_field'),
        label: l10n.quantityLabel,
        controller: _quantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }
}
