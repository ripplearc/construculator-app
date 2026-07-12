import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class MaterialCostFormFields extends StatefulWidget {
  final bool fromCostFile;
  final ValueChanged<double>? onTotalChanged;
  final ValueChanged<bool>? onSaveEnabledChanged;

  const MaterialCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
  });

  @override
  State<MaterialCostFormFields> createState() => _MaterialCostFormFieldsState();
}

class _MaterialCostFormFieldsState extends State<MaterialCostFormFields> {
  bool _showOtherDetails = false;
  final _materialTypeController = TextEditingController();
  final _perUnitCostController = TextEditingController();
  final _quantityController = TextEditingController();
  final _productLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _materialTypeController.addListener(_notifySaveEnabled);
    _perUnitCostController.addListener(_notifyTotal);
    _quantityController.addListener(_notifyTotal);
  }

  @override
  void didUpdateWidget(covariant MaterialCostFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCostFile != widget.fromCostFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyTotal());
    }
  }

  @override
  void dispose() {
    _materialTypeController.dispose();
    _perUnitCostController.dispose();
    _quantityController.dispose();
    _productLinkController.dispose();
    super.dispose();
  }

  void _notifySaveEnabled() {
    final value = _materialTypeController.text;
    widget.onSaveEnabledChanged?.call(value.trim().isNotEmpty);
    context.read<MaterialCostFormBloc>().add(MaterialCostItemTypeChanged(value));
  }

  // TODO: [CA-353] Move total calculation into BLoC when submission is wired
  void _notifyTotal() {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final price = double.tryParse(_perUnitCostController.text) ?? 0;
    final qty = double.tryParse(_quantityController.text) ?? 0;
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
          const SizedBox(height: CoreSpacing.space5),
          _buildOtherMaterialDetails(context),
          const SizedBox(height: CoreSpacing.space6),
          // TODO: [CA-336] Add assign task section
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
      // TODO: [CA-298] Populate material type from selected cost file
      CoreTextField(
        key: const Key('material_type_field'),
        hintText: l10n.materialTypeLabel,
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
        hintText: l10n.quantityLabel,
        controller: _quantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  List<Widget> _manuallyFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      BlocConsumer<MaterialCostFormBloc, MaterialCostFormState>(
        listenWhen: (_, state) => state is MaterialCostFormFailure,
        listener: (_, state) {
          if (state is MaterialCostFormFailure) {
            _materialTypeController.text = state.materialType;
          }
        },
        builder: (_, state) {
          final error =
              state is MaterialCostFormEditing ? state.itemTypeError : null;
          return CoreTextField(
            key: const Key('material_type_field'),
            hintText: l10n.materialTypeLabel,
            controller: _materialTypeController,
            errorTextList:
                error != null ? [l10n.materialTypeRequiredError] : null,
          );
        },
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('per_unit_cost_field'),
        hintText: l10n.perUnitCostLabel,
        controller: _perUnitCostController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: CoreIconWidget(
          icon: CoreIcons.dollar,
          color: colorTheme.textHeadline,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      // TODO: [CA-311] Add UOM dropdown
      CoreTextField(
        key: const Key('uom_field'),
        hintText: l10n.uomLabel,
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
        hintText: l10n.quantityLabel,
        controller: _quantityController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    ];
  }

  Widget _buildOtherMaterialDetails(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showOtherDetails) ...[
          // TODO: [CA-332] Add brand dropdown to other material details
          CoreTextField(
            key: const Key('brand_field'),
            hintText: l10n.brandLabel,
            readOnly: true,
            enabled: false,
            suffix: CoreIconWidget(
              icon: CoreIcons.arrowDropDown,
              color: colorTheme.iconGrayMid,
              size: 24,
            ),
          ),
          const SizedBox(height: CoreSpacing.space3),
          CoreTextField(
            key: const Key('product_link_field'),
            hintText: l10n.productLinkLabel,
            controller: _productLinkController,
          ),
          const SizedBox(height: CoreSpacing.space3),
        ],
        CoreButton(
          key: const Key('other_material_details_button'),
          label: l10n.otherMaterialDetailsButton,
          variant: CoreButtonVariant.secondary,
          size: CoreButtonSize.medium,
          onPressed: () => setState(() => _showOtherDetails = !_showOtherDetails),
        ),
      ],
    );
  }
}
