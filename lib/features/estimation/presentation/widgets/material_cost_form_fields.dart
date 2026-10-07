import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Longest name a person can type; a longer one can only arrive from a cost
/// file.
const int _maxNameLength = 80;

/// The quantity row is 90 dp tall in Figma: the unit button's 48 dp tap area
/// takes 5 dp from the gap above it and 5 dp from the space below it.
const double _quantityValueGap = 3;
const double _quantityBottomPadding = 7;

/// The material name, quantity with its unit, and rate rows of the "New
/// material cost" sheet.
///
// TODO: [CA-1185] add the search button inside the Rate row and the "Never priced this?" hint under it.
// TODO: [CA-1187] add the "Waste 10% · Add note" row under the rate hint.
class MaterialCostFormFields extends StatefulWidget {
  const MaterialCostFormFields({super.key});

  @override
  State<MaterialCostFormFields> createState() => _MaterialCostFormFieldsState();
}

class _MaterialCostFormFieldsState extends State<MaterialCostFormFields> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _rateFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _nameFocus.dispose();
    _quantityFocus.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<MaterialCostFormBloc>();
    return BlocBuilder<MaterialCostFormBloc, MaterialCostFormState>(
      buildWhen: (previous, current) =>
          previous.data.unit != current.data.unit ||
          _isSaving(previous) != _isSaving(current),
      builder: (context, state) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetFieldRow(
              label: l10n.materialNameLabel,
              onTap: _nameFocus.requestFocus,
              child: _SheetTextField(
                key: const Key('material_name_field'),
                readOnly: _isSaving(state),
                controller: _nameController,
                focusNode: _nameFocus,
                label: l10n.materialNameLabel,
                hintText: l10n.materialNamePlaceholder,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxNameLength),
                ],
                onChanged: (value) =>
                    bloc.add(MaterialCostItemTypeChanged(value)),
              ),
            ),
            SheetFieldRow(
              label: l10n.materialQuantityLabel,
              valueGap: _quantityValueGap,
              bottomPadding: _quantityBottomPadding,
              onTap: _quantityFocus.requestFocus,
              child: Row(
                spacing: CoreSpacing.space2,
                children: [
                  IntrinsicWidth(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: CoreSpacing.space12,
                      ),
                      child: _SheetTextField(
                        key: const Key('material_quantity_field'),
                        readOnly: _isSaving(state),
                        controller: _quantityController,
                        focusNode: _quantityFocus,
                        label: l10n.materialQuantityLabel,
                        hintText: l10n.materialQuantityPlaceholder,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [_decimalLimitFormatter(decimals: 4)],
                        onChanged: (value) =>
                            bloc.add(MaterialQuantityUpdated(value)),
                      ),
                    ),
                  ),
                  UnitPill(
                    key: const Key('material_unit_pill'),
                    unit: state.data.unit,
                    isEnabled: !_isSaving(state),
                    onUnitSelected: (unit) =>
                        bloc.add(MaterialUnitSelected(unit)),
                  ),
                ],
              ),
            ),
            SheetFieldRow(
              label: l10n.materialRateLabel,
              valueGap: CoreSpacing.space2,
              onTap: _rateFocus.requestFocus,
              child: _SheetTextField(
                key: const Key('material_rate_field'),
                readOnly: _isSaving(state),
                controller: _rateController,
                focusNode: _rateFocus,
                label: l10n.materialRateLabel,
                hintText: l10n.materialRatePlaceholder,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [_decimalLimitFormatter(decimals: 2)],
                onChanged: (value) => bloc.add(MaterialRateUpdated(value)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSaving(MaterialCostFormState state) =>
      state is MaterialCostFormSubmitting || state is MaterialCostFormSuccess;

  TextInputFormatter _decimalLimitFormatter({required int decimals}) {
    final allowed = RegExp('^\\d*\\.?\\d{0,$decimals}\$');
    return TextInputFormatter.withFunction((previous, next) {
      // A phone set to a comma-decimal language shows a comma key.
      final text = next.text.replaceAll(',', '.');
      return allowed.hasMatch(text) ? next.copyWith(text: text) : previous;
    });
  }
}

/// A borderless single-line text input that sits in a [SheetFieldRow].
///
/// The input draws 24 dp tall as in Figma, but reports a 48 dp tall tap target
/// so assistive technology can hit it.
///
// TODO: [CA-1158] replace with CoreUI's underline-style text field once it exists. https://ripplearc.youtrack.cloud/issue/CA-1158
class _SheetTextField extends StatelessWidget {
  static const double _drawnHeight = CoreSpacing.space6;
  static const double _tapHeight = CoreSpacing.space12;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  const _SheetTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hintText,
    required this.onChanged,
    required this.readOnly,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return SizedBox(
      height: _drawnHeight,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minHeight: _tapHeight,
        maxHeight: _tapHeight,
        child: Semantics(
          label: label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            maxLines: 1,
            cursorColor: colorTheme.textHeadline,
            style: textTheme.bodyLargeRegular.copyWith(
              color: colorTheme.textHeadline,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: (_tapHeight - _drawnHeight) / 2,
              ),
              hintText: hintText,
              hintStyle: textTheme.bodyLargeRegular.copyWith(
                color: colorTheme.textDisable,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
