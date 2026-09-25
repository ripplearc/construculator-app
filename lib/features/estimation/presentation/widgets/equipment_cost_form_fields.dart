import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/choice_chip_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/rate_status_badge.dart';
import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

String _formatTrimmedNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// Form fields for adding an equipment cost item.
class EquipmentCostFormFields extends StatefulWidget {
  /// When true, renders fields for selecting from a cost file; otherwise renders manual-entry fields.
  final bool fromCostFile;
  final ValueChanged<double>? onTotalChanged;
  final ValueChanged<bool>? onSaveEnabledChanged;

  /// The estimate this item is being added to. Forwarded to
  /// [EquipmentOutsizedFeeAcceptedEvent] when the user accepts an outsized
  /// delivery fee. May be null wherever the caller doesn't have one yet.
  final String? estimateId;

  /// Builds a [YourRatesBloc] backing the "Save as my rate" link and the
  /// Rate/Amount field's look-up-a-rate search button. Injected rather than
  /// resolved with `Modular.get` here, since this widget isn't a module
  /// file. Called twice: once for the bloc this widget owns for saves (see
  /// [_EquipmentCostFormFieldsState]'s own instance), and once per
  /// look-up-a-rate sheet open, matching [YourRatesBloc]'s factory
  /// registration.
  final YourRatesBloc Function() yourRatesBlocFactory;

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
    this.estimateId,
    required this.yourRatesBlocFactory,
  });

  @override
  State<EquipmentCostFormFields> createState() =>
      _EquipmentCostFormFieldsState();
}

class _EquipmentCostFormFieldsState extends State<EquipmentCostFormFields> {
  final _equipmentNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _durationController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _jobAmountController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _deliveryFocusNode = FocusNode();
  final _noteController = TextEditingController();
  final _noteFocusNode = FocusNode();

  final _daySelected = ValueNotifier<bool>(true);
  final _jobSelected = ValueNotifier<bool>(false);

  bool _deliveryExpanded = false;

  /// Owned by this widget solely for [YourRatesSaveRequested] — never
  /// dispatches Refresh/Search on it, so every state it emits is a save
  /// outcome (see [_handleYourRatesSaveState]). The look-up-a-rate sheet
  /// gets its own separate, shorter-lived instance instead (see
  /// [_openRateLookup]).
  late final YourRatesBloc _yourRatesBloc;

  @override
  void initState() {
    super.initState();
    _yourRatesBloc = widget.yourRatesBlocFactory();
    _equipmentNameController.addListener(_onEquipmentNameChanged);
    _quantityController.addListener(_notifyTotal);
    _durationController.addListener(_onDurationChanged);
    _dailyRateController.addListener(_onDailyRateChanged);
    _jobAmountController.addListener(_onJobAmountChanged);
    _deliveryFeeController.addListener(_onDeliveryFeeChanged);
    _deliveryFocusNode.addListener(_onDeliveryFocusChanged);
    _noteController.addListener(_onDescriptionChanged);
  }

  @override
  void didUpdateWidget(covariant EquipmentCostFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCostFile != widget.fromCostFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _notifyTotal();
        if (widget.fromCostFile) {
          widget.onSaveEnabledChanged?.call(false);
        } else {
          _onEquipmentNameChanged();
        }
      });
    }
  }

  @override
  void dispose() {
    _equipmentNameController.dispose();
    _quantityController.dispose();
    _durationController.dispose();
    _dailyRateController.dispose();
    _jobAmountController.dispose();
    _deliveryFeeController.dispose();
    _deliveryFocusNode.dispose();
    _noteController.dispose();
    _noteFocusNode.dispose();
    _daySelected.dispose();
    _jobSelected.dispose();
    unawaited(_yourRatesBloc.close());
    super.dispose();
  }

  void _onEquipmentNameChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentCostItemTypeChanged(_equipmentNameController.text),
    );
  }

  void _onDurationChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentDurationUpdatedEvent(_durationController.text),
    );
  }

  void _onDailyRateChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentRateUpdatedEvent(_dailyRateController.text),
    );
  }

  void _onJobAmountChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentRateUpdatedEvent(_jobAmountController.text),
    );
  }

  void _onDeliveryFeeChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentDeliveryFeeUpdatedEvent(_deliveryFeeController.text),
    );
    _notifyTotal();
  }

  void _onDeliveryFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onDescriptionChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentDescriptionUpdatedEvent(_noteController.text),
    );
  }

  void _toggleDeliveryExpanded() {
    if (_deliveryExpanded) {
      setState(() => _deliveryExpanded = false);
      _deliveryFocusNode.unfocus();
      return;
    }
    setState(() => _deliveryExpanded = true);
    // The field has no autofocus param, so it must exist in the tree
    // (post-frame) before it can accept focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deliveryFocusNode.requestFocus();
    });
  }

  void _openNoteField() {
    if (!_deliveryExpanded) {
      setState(() => _deliveryExpanded = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _noteFocusNode.requestFocus();
    });
  }

  Future<void> _showOutsizedFeeDialog(EquipmentCostFormData data) async {
    final fee = data.deliveryFee;
    if (fee == null) return;
    final isDay = data.method == EquipmentPricingMethod.day;
    final baseCost = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : (data.jobAmount ?? 0);
    final bloc = context.read<EquipmentCostFormBloc>();

    // Tapping outside the dialog pops it with a null result, which is
    // treated the same as "Go back".
    final accepted = await showDialog<bool>(
      context: context,
      builder: (_) => _OutsizedFeeDialog(
        fee: fee,
        baseCost: baseCost,
        method: data.method,
        duration: data.duration,
        equipmentType: data.equipmentType,
      ),
    );
    if (!mounted) return;

    final estimateId = widget.estimateId;
    if (accepted == true && estimateId != null) {
      bloc.add(EquipmentOutsizedFeeAcceptedEvent(estimateId: estimateId));
      return;
    }
    bloc.add(const EquipmentOutsizedFeeDeclinedEvent());
    setState(() => _deliveryExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _deliveryFocusNode.requestFocus();
      _deliveryFeeController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _deliveryFeeController.text.length,
      );
    });
  }

  void _selectMethod(EquipmentPricingMethod tapped) {
    _daySelected.value = false;
    _jobSelected.value = false;
    context.read<EquipmentCostFormBloc>().add(
      EquipmentMethodSwitchedEvent(tapped),
    );
  }

  void _notifyTotal() {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
    }
  }

  void _mirrorMethodIntoChips(EquipmentPricingMethod method) {
    _daySelected.value = method == EquipmentPricingMethod.day;
    _jobSelected.value = method == EquipmentPricingMethod.job;
  }

  // TODO: [CA-353](https://ripplearc.youtrack.cloud/issue/CA-353) Move total calculation into BLoC when submission is wired
  void _notifyTotalFromData(EquipmentCostFormData data) {
    final isDay = data.method == EquipmentPricingMethod.day;
    final hasFieldError = isDay
        ? data.fieldErrors.containsKey(EquipmentFormField.duration) ||
              data.fieldErrors.containsKey(EquipmentFormField.dailyRate)
        : data.fieldErrors.containsKey(EquipmentFormField.jobAmount);
    if (hasFieldError) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final base = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : data.jobAmount ?? 0;
    final hasDeliveryFeeError = data.fieldErrors.containsKey(
      EquipmentFormField.deliveryFee,
    );
    final delivery = hasDeliveryFeeError ? 0.0 : (data.deliveryFee ?? 0);
    // Delivery is added after the rate math, never inside it.
    widget.onTotalChanged?.call(base + delivery);
  }

  EquipmentCostFormData _dataOf(EquipmentCostFormState state) =>
      switch (state) {
        EquipmentCostFormEditing(:final data) => data,
        EquipmentCostFormOutsizedFeeConfirm(:final data) => data,
        EquipmentCostFormSubmitting(:final data) => data,
        EquipmentCostFormSuccess(:final data) => data,
        EquipmentCostFormFailure(:final data) => data,
        EquipmentCostFormInitial() => const EquipmentCostFormData(),
      };

  List<String>? _errorList(String? text) => text == null ? null : [text];

  String? _durationErrorText(BuildContext context, EquipmentCostFormData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors[EquipmentFormField.duration]) {
      EquipmentFieldError.durationNotPositive =>
        l10n.equipmentDurationNotPositiveError,
      EquipmentFieldError.durationNotHalfDay =>
        l10n.equipmentDurationNotHalfDayError,
      EquipmentFieldError.durationTooLarge =>
        l10n.equipmentDurationTooLargeError,
      _ => null,
    };
  }

  String? _rateErrorText(BuildContext context, EquipmentCostFormData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors[EquipmentFormField.dailyRate]) {
      EquipmentFieldError.rateOutOfRange => l10n.equipmentRateOutOfRangeError,
      _ => null,
    };
  }

  String? _amountErrorText(BuildContext context, EquipmentCostFormData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors[EquipmentFormField.jobAmount]) {
      EquipmentFieldError.rateOutOfRange => l10n.equipmentAmountOutOfRangeError,
      _ => null,
    };
  }

  String _deliveryRowValue(BuildContext context, double? fee) {
    final raw = _deliveryFeeController.text;
    return switch ((_deliveryFocusNode.hasFocus, raw.isEmpty, fee)) {
      (true, false, _) => '${DisplayFormatter.currency.currencySymbol}$raw',
      (_, _, null) => context.l10n.equipmentDeliveryFeeUnsetText,
      (_, _, final fee?) => DisplayFormatter.currency.format(fee),
    };
  }

  String _deliveryRowText(BuildContext context, double? fee) =>
      '${context.l10n.equipmentDeliveryRowLabel} '
      '${_deliveryRowValue(context, fee)}';

  Widget? _rateStatusBadge(BuildContext context, RateStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      RateStatus.sampleRateUnverified => RateStatusBadge(
        key: const Key('rate_status_badge'),
        label: l10n.equipmentRateStatusSampleRateBadge,
        variant: RateStatusBadgeVariant.orange,
      ),
      RateStatus.ownRateConfirmed => RateStatusBadge(
        key: const Key('rate_status_badge'),
        label: l10n.equipmentRateStatusYourRateBadge,
        variant: RateStatusBadgeVariant.green,
      ),
      RateStatus.ownRateUnconfirmed || RateStatus.missing => null,
    };
  }

  // No mechanism anywhere in this app resolves the caller's real company id
  // (no companyId on ProjectRepository/Project, no CurrentCompanyRepository).
  // Per YourRatesRepository.save's own doc comment, companyId only matters
  // for writes, which the backend validates against the caller's actual
  // company membership — an empty id fails that check server-side instead
  // of writing to the wrong company.
  // TODO: [CA-1179](https://ripplearc.youtrack.cloud/issue/CA-1179) Replace
  // with a real company id once CurrentCompanyResolver exists.
  String get _currentCompanyId => '';

  YourRateEntry _buildYourRateEntry(
    EquipmentCostFormWithData data, {
    String? entryLabel,
  }) {
    final isDay = data.method == EquipmentPricingMethod.day;
    return YourRateEntry(
      id: '',
      companyId: _currentCompanyId,
      itemName: _equipmentNameController.text,
      category: CostItemType.equipment,
      rate: Money(amount: (isDay ? data.dailyRate : data.jobAmount) ?? 0),
      savedAt: DateTime.now(),
      equipmentMethod: data.method,
      entryLabel: entryLabel,
    );
  }

  void _saveAsMyRate(EquipmentCostFormWithData data) {
    _yourRatesBloc.add(YourRatesSaveRequested(_buildYourRateEntry(data)));
  }

  // Reacts to the dedicated _yourRatesBloc instance this widget owns for
  // saves only (never dispatches Refresh/Search on it — see initState), so
  // every state it emits is a save outcome. The collision/failure branching
  // itself lives in YourRatesBloc, not here — this just maps each resulting
  // state to its UI effect.
  void _handleYourRatesSaveState(BuildContext context, YourRatesState state) {
    switch (state) {
      case YourRatesSaveCollision(:final entry):
        unawaited(_promptEntryLabelAndRetry(context, entry));
      case YourRatesSaveFailed():
        _showSnack(context, context.l10n.yourRatesSaveFailedError);
      case YourRatesSaveSucceeded():
      case YourRatesLoading():
      case YourRatesLoaded():
      case YourRatesSearchResults():
      case YourRatesError():
        break;
    }
  }

  Future<void> _promptEntryLabelAndRetry(
    BuildContext context,
    YourRateEntry entry,
  ) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _EntryLabelDialog(),
    );
    if (label == null || !mounted) return;
    _yourRatesBloc.add(
      YourRatesSaveRequested(entry.copyWith(entryLabel: label)),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // True when the rate/amount field currently in play (Day pricing reads
  // dailyRate, Job pricing reads jobAmount) has a validation error. Checked
  // by [_saveAsMyRateLink] alongside [EquipmentCostFormWithData.itemTypeError]
  // so the link can't fire a save built from an equipment name or rate the
  // form itself is showing red.
  bool _hasRateFieldError(EquipmentCostFormWithData data) {
    final key = data.method == EquipmentPricingMethod.day
        ? 'dailyRate'
        : 'jobAmount';
    return data.fieldErrors.containsKey(key);
  }

  // Shown for any rate the contractor hasn't yet saved to Your rates:
  // RateStatus.missing (nothing typed) shows the look-up-a-rate search
  // button instead — see the caller — so this only covers
  // ownRateConfirmed/sampleRateUnverified. Also withheld while the
  // equipment name or the rate/amount field itself has a validation error,
  // so the link can't save an empty name or an out-of-range rate.
  Widget? _saveAsMyRateLink(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    if (data.rateStatus == RateStatus.missing ||
        data.itemTypeError != null ||
        _hasRateFieldError(data)) {
      return null;
    }
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      button: true,
      label: l10n.equipmentSaveAsMyRateLink,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('save_as_my_rate_link'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _saveAsMyRate(data),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.centerRight,
          child: Text(
            l10n.equipmentSaveAsMyRateLink,
            style: textTheme.bodySmallSemiBold.copyWith(
              color: colorTheme.textLink,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _lookupRateButtonWhenEmpty(
    BuildContext context,
    EquipmentCostFormData data,
  ) {
    if (data.rateStatus != RateStatus.missing) return null;
    final colorTheme = context.colorTheme;
    return Semantics(
      button: true,
      label: context.l10n.yourRatesLookupButton,
      excludeSemantics: true,
      // TODO: [CA-1252](https://ripplearc.youtrack.cloud/issue/CA-1252) Replace with CoreUI's outlined icon button once it exists.
      child: GestureDetector(
        key: const Key('lookup_rate_button'),
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_openRateLookup(context, data.method)),
        child: SizedBox(
          width: CoreSpacing.space12,
          height: CoreSpacing.space9,
          child: Center(
            child: Container(
              width: CoreSpacing.space9,
              height: CoreSpacing.space9,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: colorTheme.lineMid),
                borderRadius: BorderRadius.circular(CoreSpacing.space2),
              ),
              child: CoreIconWidget(
                icon: CoreIcons.search,
                color: colorTheme.iconGrayMid,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRateLookup(
    BuildContext context,
    EquipmentPricingMethod method,
  ) async {
    final entry = await YourRatesLookupSheet.show(
      context: context,
      method: method,
      blocFactory: widget.yourRatesBlocFactory,
    );
    if (entry == null || !mounted) return;
    if (_equipmentNameController.text.trim().isEmpty) {
      _equipmentNameController.text = entry.itemName;
    }
    (method == EquipmentPricingMethod.day
            ? _dailyRateController
            : _jobAmountController)
        .text = _formatTrimmedNumber(
      entry.rate.amount,
    );
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
          // TODO: [CA-336](https://ripplearc.youtrack.cloud/issue/CA-336) Add assign task section
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
    final textTheme = context.textTheme;
    return [
      BlocListener<YourRatesBloc, YourRatesState>(
        bloc: _yourRatesBloc,
        listener: _handleYourRatesSaveState,
        child: BlocConsumer<EquipmentCostFormBloc, EquipmentCostFormState>(
          listener: (_, state) {
            final data = _dataOf(state);
            if (state is EquipmentCostFormOutsizedFeeConfirm) {
              _showOutsizedFeeDialog(data);
            }
            widget.onSaveEnabledChanged?.call(data.isValid);
            _mirrorMethodIntoChips(data.method);
            _notifyTotalFromData(data);
          },
          builder: (_, state) {
            final data = _dataOf(state);
            final isDay = data.method == EquipmentPricingMethod.day;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UnderlineTextField(
                  key: const Key('equipment_name_field'),
                  label: l10n.equipmentNameLabel,
                  hintText: l10n.equipmentNamePlaceholder,
                  controller: _equipmentNameController,
                ),
                const SizedBox(height: CoreSpacing.space5),
                Text(
                  l10n.equipmentBasisLabel,
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space1),
                Row(
                  children: [
                    ChoiceChipToggle(
                      key: const Key('day_method_chip'),
                      label: l10n.equipmentDayMethodLabel,
                      selected: _daySelected,
                      onTap: () => _selectMethod(EquipmentPricingMethod.day),
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    ChoiceChipToggle(
                      key: const Key('job_method_chip'),
                      label: l10n.equipmentJobMethodLabel,
                      selected: _jobSelected,
                      onTap: () => _selectMethod(EquipmentPricingMethod.job),
                    ),
                  ],
                ),
                const SizedBox(height: CoreSpacing.space5),
                if (isDay) ...[
                  UnderlineTextField(
                    key: const Key('duration_field'),
                    label: l10n.equipmentDurationLabel,
                    hintText: l10n.equipmentDurationPlaceholder,
                    controller: _durationController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: Text(
                      l10n.equipmentDurationSuffix,
                      style: textTheme.bodyMediumRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                    errorTextList: _errorList(
                      _durationErrorText(context, data),
                    ),
                  ),
                  const SizedBox(height: CoreSpacing.space5),
                  UnderlineTextField(
                    key: const Key('rate_field'),
                    label: l10n.equipmentRateLabel,
                    controller: _dailyRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    labelTrailing: _rateStatusBadge(context, data.rateStatus),
                    trailingAction:
                        _saveAsMyRateLink(context, data) ??
                        _lookupRateButtonWhenEmpty(context, data),
                    errorTextList: _errorList(_rateErrorText(context, data)),
                  ),
                ] else
                  UnderlineTextField(
                    key: const Key('amount_field'),
                    label: l10n.equipmentAmountLabel,
                    controller: _jobAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    labelTrailing: _rateStatusBadge(context, data.rateStatus),
                    trailingAction:
                        _saveAsMyRateLink(context, data) ??
                        _lookupRateButtonWhenEmpty(context, data),
                    errorTextList: _errorList(_amountErrorText(context, data)),
                  ),
                const SizedBox(height: CoreSpacing.space5),
                _buildDeliveryFeeSection(context, data),
              ],
            );
          },
        ),
      ),
    ];
  }

  Widget _buildDeliveryFeeSection(
    BuildContext context,
    EquipmentCostFormData data,
  ) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        0,
        CoreSpacing.space4,
        _deliveryExpanded ? CoreSpacing.space3 : 0,
      ),
      decoration: BoxDecoration(
        color: colorTheme.backgroundGrayLight,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        // Figma node 66337:162350's "Details Row" instance strokes the
        // whole panel with `#eaecf0` at 1px — colorTheme.lineLight resolves
        // to exactly that (gray200, 0xFFEAECF0 in ripplearc_coreui's own
        // token file), confirmed directly rather than guessed.
        border: Border.all(color: colorTheme.lineLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Figma node 66337:162350's "Details Row" packs the value,
              // dot, and "Add note" tightly together on the left, with only
              // the chevron pushed to the far right — so the dot and "Add
              // note" must sit in the same Row, not in separate Expanded
              // siblings (which would leave a gap between them).
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Semantics(
                        button: true,
                        label: _deliveryRowText(context, data.deliveryFee),
                        excludeSemantics: true,
                        child: GestureDetector(
                          key: const Key('delivery_fee_row'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggleDeliveryExpanded,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${l10n.equipmentDeliveryRowLabel} ',
                                            style: textTheme.bodyMediumRegular
                                                .copyWith(
                                                  color: colorTheme.textBody,
                                                ),
                                          ),
                                          TextSpan(
                                            text: _deliveryRowValue(
                                              context,
                                              data.deliveryFee,
                                            ),
                                            style: textTheme.bodyMediumSemiBold
                                                .copyWith(
                                                  color:
                                                      colorTheme.textHeadline,
                                                ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: CoreSpacing.space1,
                                    ),
                                    child: Text(
                                      '·',
                                      style: textTheme.bodySmallRegular
                                          .copyWith(
                                            color: colorTheme.textDisable,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: l10n.equipmentDeliveryAddNoteLink,
                      excludeSemantics: true,
                      child: GestureDetector(
                        key: const Key('delivery_fee_add_note_link'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _openNoteField,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.equipmentDeliveryAddNoteLink,
                            style: textTheme.bodyMediumSemiBold.copyWith(
                              color: colorTheme.textLink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Purely decorative: the labeled header zone to its left
              // already exposes the same expand/collapse action to a11y
              // tools, so this icon is excluded rather than adding a second,
              // unlabeled tappable node to the semantics tree.
              ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleDeliveryExpanded,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedRotation(
                      turns: _deliveryExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: CoreIconWidget(
                        icon: CoreIcons.arrowDown,
                        color: colorTheme.iconGrayMid,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_deliveryExpanded) ...[
            const SizedBox(height: CoreSpacing.space3),
            UnderlineTextField(
              key: const Key('delivery_fee_field'),
              label: l10n.equipmentDeliveryRowLabel,
              controller: _deliveryFeeController,
              focusNode: _deliveryFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefix: Text(
                '\$',
                style: textTheme.bodyLargeRegular.copyWith(
                  color: colorTheme.textBody,
                ),
              ),
            ),
            const SizedBox(height: CoreSpacing.space3),
            UnderlineTextField(
              key: const Key('delivery_note_field'),
              label: l10n.equipmentNoteLabel,
              controller: _noteController,
              focusNode: _noteFocusNode,
              hintText: l10n.equipmentNotePlaceholder,
            ),
          ],
        ],
      ),
    );
  }
}

class _OutsizedFeeDialog extends StatelessWidget {
  const _OutsizedFeeDialog({
    required this.fee,
    required this.baseCost,
    required this.method,
    required this.duration,
    required this.equipmentType,
  });

  final double fee;
  final double baseCost;

  final EquipmentPricingMethod method;

  final double? duration;

  final String equipmentType;

  String _formatDurationPhrase(BuildContext context, double value) {
    final l10n = context.l10n;
    if (value == 1) return l10n.equipmentDeliveryFeeOutsizedDialogOneDay;
    if (value == 0.5) return l10n.equipmentDeliveryFeeOutsizedDialogHalfDay;
    return l10n.equipmentDeliveryFeeOutsizedDialogDurationDays(
      _formatTrimmedNumber(value),
    );
  }

  TextSpan _withBoldAmounts(
    String text,
    List<String> amounts, {
    required TextStyle regular,
    required TextStyle bold,
  }) {
    final pattern = RegExp(amounts.map(RegExp.escape).join('|'));
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(text: match.group(0), style: bold));
      cursor = match.end;
    }
    if (cursor < text.length) spans.add(TextSpan(text: text.substring(cursor)));
    return TextSpan(style: regular, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isDay = method == EquipmentPricingMethod.day;
    final bodyText = isDay
        ? l10n.equipmentDeliveryFeeOutsizedDialogBodyDay(
            DisplayFormatter.currency.format(fee),
            DisplayFormatter.currency.format(baseCost),
            _formatDurationPhrase(context, duration ?? 0),
            equipmentType.trim().isEmpty
                ? l10n.equipmentDeliveryFeeOutsizedDialogGenericItem
                : equipmentType.trim(),
          )
        : l10n.equipmentDeliveryFeeOutsizedDialogBody(
            DisplayFormatter.currency.format(fee),
            DisplayFormatter.currency.format(baseCost),
          );
    return Dialog(
      backgroundColor: sheetSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      // 22px padding and the 340/52 dimensions below come directly from the
      // Figma spec (node 65354:146175) and don't land on a named CoreSpacing
      // step, so they're literal rather than tokenized.
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.equipmentDeliveryFeeOutsizedDialogTitle,
                key: const Key('outsized_fee_dialog_title'),
                style: textTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Text.rich(
                _withBoldAmounts(
                  bodyText,
                  [
                    DisplayFormatter.currency.format(fee),
                    DisplayFormatter.currency.format(baseCost),
                  ],
                  regular: textTheme.bodyMediumRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                  bold: textTheme.bodyMediumSemiBold.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                key: const Key('outsized_fee_dialog_body'),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: CoreButton(
                      key: const Key('outsized_fee_dialog_go_back_button'),
                      label: l10n.equipmentDeliveryFeeOutsizedDialogGoBack,
                      variant: CoreButtonVariant.secondary,
                      size: CoreButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: CoreSpacing.space3),
                  Expanded(
                    child: CoreButton(
                      key: const Key('outsized_fee_dialog_add_it_button'),
                      label: l10n.equipmentDeliveryFeeOutsizedDialogAddIt,
                      variant: CoreButtonVariant.primary,
                      size: CoreButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prompts for the freeform label required to save a rate that collides
/// with an existing "Your rates" entry for the same equipment (Decision 55):
/// [YourRatesRepository.save] rejects an unlabeled save into an
/// already-populated (companyId, category, itemName) grouping rather than
/// guessing which row to overwrite.
///
/// Returns the typed label via `Navigator.pop`, or null if cancelled.
class _EntryLabelDialog extends StatefulWidget {
  const _EntryLabelDialog();

  @override
  State<_EntryLabelDialog> createState() => _EntryLabelDialogState();
}

class _EntryLabelDialogState extends State<_EntryLabelDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) {
      setState(() => _error = context.l10n.yourRatesEntryLabelRequiredError);
      return;
    }
    Navigator.of(context).pop(label);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Dialog(
      backgroundColor: colorTheme.pageBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.yourRatesEntryLabelDialogTitle,
                key: const Key('entry_label_dialog_title'),
                style: textTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Text(
                l10n.yourRatesEntryLabelDialogBody,
                style: textTheme.bodyMediumRegular.copyWith(
                  color: colorTheme.textBody,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              CoreTextField(
                key: const Key('entry_label_field'),
                hintText: l10n.yourRatesEntryLabelHint,
                controller: _controller,
                errorTextList: switch (_error) {
                  final error? => [error],
                  null => null,
                },
              ),
              const SizedBox(height: CoreSpacing.space3),
              Row(
                children: [
                  Expanded(
                    child: CoreButton(
                      key: const Key('entry_label_dialog_cancel_button'),
                      label: l10n.yourRatesEntryLabelCancel,
                      variant: CoreButtonVariant.secondary,
                      size: CoreButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: CoreSpacing.space3),
                  Expanded(
                    child: CoreButton(
                      key: const Key('entry_label_dialog_save_button'),
                      label: l10n.yourRatesEntryLabelSave,
                      variant: CoreButtonVariant.primary,
                      size: CoreButtonSize.medium,
                      onPressed: _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
