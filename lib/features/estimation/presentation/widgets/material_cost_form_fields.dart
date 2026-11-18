import 'dart:async';
import 'dart:math' as math;

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/material_cost_form_bloc/material_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/helpers/editable_number_text.dart';
import 'package:construculator/features/estimation/presentation/helpers/sample_rate_row.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/features/estimation/presentation/widgets/entry_label_dialog.dart';
import 'package:construculator/features/estimation/presentation/widgets/material_rate_lookup_sheet.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_field_row.dart';
import 'package:construculator/features/estimation/presentation/widgets/unit_pill.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/currency_display_controller.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
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

enum _DefaultSave { idle, saving, saved, failed }

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

  /// The sample cost file rates the Look up a rate sheet lists for a search.
  final List<SampleRateRow> Function(String query) sampleRatesFor;

  const MaterialCostFormFields({
    super.key,
    this.initialRateEntry,
    this.initialName,
    required this.yourRatesBlocFactory,
    required this.clock,
    this.sampleRatesFor = noSampleRates,
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
  late final YourRatesBloc _saveBloc;
  _DefaultSave _defaultSave = _DefaultSave.idle;
  double? _rateBeingSaved;
  String? _savedItemName;
  bool _isAskingForLabel = false;

  @override
  void initState() {
    super.initState();
    _saveBloc = widget.yourRatesBlocFactory();
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
      sampleRatesFor: widget.sampleRatesFor,
    );
    if (pick == null || !mounted) return;
    _rateController.text = editableNumberText(pick.rate.amount);
    final bloc = context.read<MaterialCostFormBloc>();
    switch (pick) {
      case MaterialLookupYourRate(:final entry):
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = entry.itemName;
        }
        bloc.add(MaterialRateLookedUp(entry));
      case MaterialLookupSampleRate(:final row):
        final typedName = _nameController.text;
        _nameController.text = row.materialNameAfter(typedName);
        bloc.add(
          MaterialSampleRatePicked(
            itemName: _nameController.text,
            rate: row.rate.amount,
            unit: row.unit,
            typedName: typedName,
          ),
        );
    }
  }

  void _saveAsDefault(MaterialCostFormData data) {
    final rate = data.rate;
    if (rate == null) return;
    _rateBeingSaved = rate;
    _savedItemName = data.itemName.trim();
    _saveBloc.add(
      YourRatesSaveRequested(
        YourRateEntry(
          id: '',
          companyId: '',
          itemName: data.itemName.trim(),
          category: CostItemType.material,
          rate: Money(amount: rate),
          unit: data.unit,
          savedAt: widget.clock.now(),
          entryLabel: data.unit?.name,
        ),
      ),
    );
  }

  void _onDefaultSaveState(BuildContext context, YourRatesState state) {
    switch (state) {
      case YourRatesSaving():
        setState(() => _defaultSave = _DefaultSave.saving);
      case YourRatesSaveCollision(:final entry) ||
          YourRatesSaveLabelTaken(:final entry):
        setState(() => _defaultSave = _DefaultSave.idle);
        if (!_isAskingForLabel) unawaited(_askForLabel(entry));
      case YourRatesSaveSucceeded():
        setState(() => _defaultSave = _DefaultSave.saved);
        if (_rateBeingSaved case final rate?) {
          context.read<MaterialCostFormBloc>().add(
            MaterialRateSavedAsDefault(rate),
          );
        }
      case YourRatesSaveFailed() || YourRatesSaveNoCompany():
        setState(() => _defaultSave = _DefaultSave.failed);
      case YourRatesLoading() ||
          YourRatesRetrying() ||
          YourRatesLoaded() ||
          YourRatesSearchResults() ||
          YourRatesError():
        break;
    }
  }

  Future<void> _askForLabel(YourRateEntry entry) async {
    _isAskingForLabel = true;
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: _saveBloc,
        child: EntryLabelDialog(entry: entry.copyWith(entryLabel: clearField)),
      ),
    );
    _isAskingForLabel = false;
  }

  @override
  void dispose() {
    unawaited(_saveBloc.close());
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
    return BlocListener<YourRatesBloc, YourRatesState>(
      bloc: _saveBloc,
      listener: _onDefaultSaveState,
      child: _buildFields(context),
    );
  }

  Widget _buildFields(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<MaterialCostFormBloc>();
    return BlocBuilder<MaterialCostFormBloc, MaterialCostFormState>(
      buildWhen: (previous, current) =>
          previous.data.unit != current.data.unit ||
          previous.data.rateStatus != current.data.rateStatus ||
          previous.data.offersSaveAsDefault !=
              current.data.offersSaveAsDefault ||
          ((current.data.offersSaveAsDefault ||
                  _defaultSave == _DefaultSave.saved) &&
              (previous.data.rate != current.data.rate ||
                  previous.data.itemName != current.data.itemName)) ||
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
              labelTrailing:
                  state.data.rateStatus == RateStatus.sampleRateUnverified
                  ? CoreStatusBadge(
                      key: const Key('rate_status_badge'),
                      label: l10n.materialSampleRateBadge,
                      size: CoreStatusBadgeSize.compact,
                    )
                  : null,
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
                  if (state.data.offersSaveAsDefault)
                    _SaveAsDefaultLink(
                      isSaving: _defaultSave == _DefaultSave.saving,
                      onTap: () => _saveAsDefault(state.data),
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
            if (_isRateMissing(state))
              _FieldHint(
                key: const Key('material_rate_lookup_hint'),
                text: l10n.materialRateLookupHint,
              ),
            if (state.data.offersSaveAsDefault)
              _SaveAsDefaultHint(data: state.data),
            if (state.data.offersSaveAsDefault &&
                _defaultSave == _DefaultSave.failed)
              _FieldHint(
                key: const Key('save_as_default_error'),
                text: l10n.yourRatesSaveFailedError,
                isError: true,
              ),
            if (_defaultSave == _DefaultSave.saved &&
                state.data.rateStatus == RateStatus.ownRateConfirmed &&
                state.data.itemName.trim() == _savedItemName)
              _FieldHint(
                key: const Key('saved_as_default_helper_text'),
                text: l10n.materialSavedToYourRatesHint(
                  l10n.yourRatesName,
                  state.data.nameToFindRateBy.toLowerCase(),
                ),
                emphasis: l10n.yourRatesName,
              ),
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

class _SaveAsDefaultHint extends StatelessWidget {
  final MaterialCostFormData data;

  const _SaveAsDefaultHint({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = DisplayFormatter.currency.format(data.rate);
    final price = switch (data.unit) {
      final unit? =>
        '$amount ${l10n.materialRatePerUnitSuffix(unit.displayName(l10n))}',
      null => amount,
    };
    return _FieldHint(
      key: const Key('save_as_default_helper_text'),
      text: l10n.materialSaveAsDefaultHelperText(
        price,
        l10n.yourRatesName,
        data.nameToFindRateBy.toLowerCase(),
      ),
      emphasis: l10n.yourRatesName,
    );
  }
}

// TODO: [CA-1510] use CoreUI's text link once it exists. https://ripplearc.youtrack.cloud/issue/CA-1510
class _SaveAsDefaultLink extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onTap;

  const _SaveAsDefaultLink({required this.isSaving, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.materialSaveAsDefaultLink;
    return Semantics(
      button: true,
      enabled: !isSaving,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('save_as_default_link'),
        behavior: HitTestBehavior.opaque,
        onTap: isSaving ? null : onTap,
        child: IntrinsicWidth(
          child: SizedBox(
            height: _SheetTextField._drawnHeight,
            child: OverflowBox(
              maxHeight: _lookupButtonTapSize,
              child: SizedBox(
                height: _lookupButtonTapSize,
                child: Center(
                  child: Text(
                    label,
                    style: context.textTheme.bodyLargeSemiBold.copyWith(
                      color: isSaving
                          ? context.colorTheme.textDisable
                          : context.colorTheme.textLink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldHint extends StatelessWidget {
  final String text;
  final String? emphasis;
  final bool isError;

  const _FieldHint({
    super.key,
    required this.text,
    this.emphasis,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final style = context.textTheme.bodySmallRegular.copyWith(
      color: isError ? colorTheme.textError : colorTheme.textBody,
    );
    final emphasis = this.emphasis;
    final at = emphasis == null ? -1 : text.indexOf(emphasis);
    return Padding(
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
            icon: isError ? CoreIcons.error : CoreIcons.info,
            size: CoreIconSize.size16,
            color: isError ? colorTheme.iconRed : colorTheme.iconGrayMid,
          ),
          Expanded(
            child: emphasis == null || at < 0
                ? Text(text, style: style)
                : Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        TextSpan(text: text.substring(0, at)),
                        TextSpan(
                          text: emphasis,
                          style: context.textTheme.bodySmallSemiBold.copyWith(
                            color: colorTheme.textBody,
                          ),
                        ),
                        TextSpan(text: text.substring(at + emphasis.length)),
                      ],
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
