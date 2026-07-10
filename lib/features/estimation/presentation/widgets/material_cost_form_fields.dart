import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Form fields for adding a material cost item.
class MaterialCostFormFields extends StatefulWidget {
  /// When true, renders fields for selecting from a cost file; otherwise renders manual-entry fields.
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyTotal();
      });
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

  void _notifySaveEnabled() =>
      widget.onSaveEnabledChanged?.call(
        _materialTypeController.text.trim().isNotEmpty,
      );

  // TODO: [CA-355] Move total calculation into BLoC when submission is wired
  void _notifyTotal() {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final rawPrice = double.tryParse(_perUnitCostController.text) ?? 0;
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
          const SizedBox(height: CoreSpacing.space5),
          _buildOtherMaterialDetails(context),
          const SizedBox(height: CoreSpacing.space6),
          // TODO: [CA-336] Add assign task section https://ripplearc.youtrack.cloud/issue/CA-336
        ],
      ),
    );
  }

  List<Widget> _fromCostFileFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      // TODO: [CA-298] Wire cost file dropdown to CostFileDataSource https://ripplearc.youtrack.cloud/issue/CA-298
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
      // TODO: [CA-298] Populate material type from selected cost file https://ripplearc.youtrack.cloud/issue/CA-298
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
      CoreTextField(
        key: const Key('material_type_field'),
        label: l10n.materialTypeLabel,
        controller: _materialTypeController,
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('per_unit_cost_field'),
        label: l10n.perUnitCostLabel,
        controller: _perUnitCostController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: CoreIconWidget(
          icon: CoreIcons.dollar,
          color: colorTheme.textHeadline,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      // TODO: [CA-311] Add UOM dropdown https://ripplearc.youtrack.cloud/issue/CA-311
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
        label: l10n.quantityLabel,
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
          // TODO: [CA-332] Add brand dropdown to other material details https://ripplearc.youtrack.cloud/issue/CA-332
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
            label: l10n.productLinkLabel,
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
