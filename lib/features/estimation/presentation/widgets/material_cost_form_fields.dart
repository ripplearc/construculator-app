import 'dart:async';
import 'dart:math' as math;

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/editable_number_text.dart';
import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_rate_lookup_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/currency_display_controller.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const int _maxNameLength = 80;

const int _maxWholeDigits = 9;

const double _quantityValueGap = 3;
const double _quantityBottomPadding = 6;
const double _nameBottomPadding = 6;

const double _lookupButtonTapSize = 48;

/// The material name, quantity with its unit, and rate rows of the "New
/// material cost" sheet.
///
// TODO: [CA-1184] open a picked saved rate on the quantity-only screen instead of this full form. https://ripplearc.youtrack.cloud/issue/CA-1184
// TODO: [CA-1187] add the "Waste 10% · Add note" row under the rate hint. https://ripplearc.youtrack.cloud/issue/CA-1187
class MaterialCostFormFields extends StatefulWidget {
  /// A rate picked on the Your recents sheet before the form opened. Fills the
  /// name, rate and unit.
  final YourRateEntry? initialRateEntry;

  /// A name typed on the Your recents search before the form opened. Fills the
  /// name and leaves the rate empty. Ignored when [initialRateEntry] is set.
  final String? initialName;

  /// Creates the bloc behind the Look up a rate sheet, opened from the search
  /// button in the Rate row.
  final YourRatesBloc Function() yourRatesBlocFactory;

  /// Dates the "Used …" and "Saved …" line under each rate on the Look up a
  /// rate sheet.
  final Clock clock;

  const MaterialCostFormFields({
    super.key,
    this.initialRateEntry,
    this.initialName,
    required this.yourRatesBlocFactory,
    required this.clock,
  });

  @override
  State<MaterialCostFormFields> createState() => _MaterialCostFormFieldsState();
}

class _MaterialCostFormFieldsState extends State<MaterialCostFormFields> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _nameFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _rateFocus = FocusNode();
  late final _rateController = CurrencyDisplayController(focusNode: _rateFocus);

  @override
  void initState() {
    super.initState();
    final bloc = context.read<MaterialCostFormBloc>();
    if (widget.initialRateEntry case final entry?) {
      _nameController.text = entry.itemName;
      _rateController.text = editableNumberText(entry.rate.amount);
      bloc.add(MaterialSavedRateRecalled(entry));
    } else if (widget.initialName case final name?) {
      _nameController.text = name;
      bloc.add(MaterialCostItemTypeChanged(name));
    }
  }

  Future<void> _openRateLookup() async {
    final pick = await MaterialRateLookupSheet.show(
      context: context,
      initialQuery: _nameController.text.trim(),
      clock: widget.clock,
      blocFactory: widget.yourRatesBlocFactory,
      sampleRatesFor: noSampleRates,
    );
    if (pick is! MaterialLookupYourRate || !mounted) return;
    final entry = pick.entry;
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = entry.itemName;
    }
    _rateController.text = editableNumberText(entry.rate.amount);
    context.read<MaterialCostFormBloc>().add(MaterialRateLookedUp(entry));
  }

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
          _isRateMissing(previous) != _isRateMissing(current) ||
          _isSaving(previous) != _isSaving(current),
      builder: (context, state) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetFieldRow(
              label: l10n.materialNameLabel,
              bottomPadding: _nameBottomPadding,
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
                  _SheetTextField(
                    key: const Key('material_quantity_field'),
                    fitsText: true,
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
              child: Row(
                spacing: CoreSpacing.space1,
                children: [
                  Expanded(
                    child: Row(
                      spacing: CoreSpacing.space1,
                      children: [
                        _SheetTextField(
                          key: const Key('material_rate_field'),
                          fitsText: true,
                          readOnly: _isSaving(state),
                          controller: _rateController,
                          focusNode: _rateFocus,
                          label: l10n.materialRateLabel,
                          hintText: l10n.materialRatePlaceholder,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            _decimalLimitFormatter(decimals: 2),
                          ],
                          onChanged: (value) =>
                              bloc.add(MaterialRateUpdated(value)),
                        ),
                        if (state.data.unit case final unit?)
                          Flexible(
                            child: Text(
                              l10n.materialRatePerUnitSuffix(
                                unit.displayName(l10n),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyMediumRegular
                                  .copyWith(color: context.colorTheme.textBody),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isRateMissing(state))
                    SizedBox(
                      width: _lookupButtonTapSize,
                      height: _SheetTextField._drawnHeight,
                      child: OverflowBox(
                        maxHeight: _lookupButtonTapSize,
                        child: CoreOutlinedIconButton(
                          key: const Key('lookup_rate_button'),
                          icon: CoreIcons.search,
                          semanticLabel: l10n.yourRatesLookupButton,
                          onTap: () => unawaited(_openRateLookup()),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isRateMissing(state)) const _RateLookupHint(),
            const SizedBox(height: CoreSpacing.space4),
          ],
        ),
      ),
    );
  }

  bool _isRateMissing(MaterialCostFormState state) =>
      state.data.rateStatus == RateStatus.missing;

  bool _isSaving(MaterialCostFormState state) =>
      state is MaterialCostFormSubmitting || state is MaterialCostFormSuccess;

  TextInputFormatter _decimalLimitFormatter({required int decimals}) {
    final allowed = RegExp(
      '^\\d{0,$_maxWholeDigits}(\\.\\d{0,$decimals})?\$',
    );
    return TextInputFormatter.withFunction((previous, next) {
      // A phone set to a comma-decimal language shows a comma key.
      final text = next.text.replaceAll(',', '.');
      return allowed.hasMatch(text) ? next.copyWith(text: text) : previous;
    });
  }
}

class _RateLookupHint extends StatelessWidget {
  const _RateLookupHint();

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    return Padding(
      key: const Key('material_rate_lookup_hint'),
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space5,
        CoreSpacing.space2,
        CoreSpacing.space5,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpacing.space1,
        children: [
          CoreIconWidget(
            icon: CoreIcons.info,
            size: CoreIconSize.size16,
            color: colorTheme.iconGrayMid,
          ),
          Expanded(
            child: Text(
              context.l10n.materialRateLookupHint,
              style: context.textTheme.bodySmallRegular.copyWith(
                color: colorTheme.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: [CA-1158] replace with CoreUI's underline-style text field once it exists. https://ripplearc.youtrack.cloud/issue/CA-1158
class _SheetTextField extends StatelessWidget {
  static const double _drawnHeight = CoreSpacing.space6;
  static const double _tapHeight = CoreSpacing.space12;
  static const double _tapWidth = CoreSpacing.space12;
  static const double _cursorAllowance = 3;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String> onChanged;
  final bool readOnly;

  final bool fitsText;

  const _SheetTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hintText,
    required this.onChanged,
    required this.readOnly,
    this.fitsText = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final textStyle = textTheme.bodyLargeRegular.copyWith(
      color: colorTheme.textHeadline,
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final width = fitsText ? _textWidth(context, textStyle) : null;
        return SizedBox(
          height: _drawnHeight,
          width: width,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minHeight: _tapHeight,
            maxHeight: _tapHeight,
            minWidth: width == null ? null : math.max(width, _tapWidth),
            maxWidth: width == null ? null : math.max(width, _tapWidth),
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
                style: textStyle,
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
      },
    );
  }

  double _textWidth(BuildContext context, TextStyle style) {
    final shownStyle =
        Theme.of(context).textTheme.bodyLarge?.merge(style) ?? style;
    final painter = TextPainter(
      // Measures what the controller paints, such as "$52.00" for "52".
      text: controller.text.isEmpty
          ? TextSpan(text: hintText, style: shownStyle)
          : controller.buildTextSpan(
              context: context,
              style: shownStyle,
              withComposing: false,
            ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    return painter.width + _cursorAllowance;
  }
}
