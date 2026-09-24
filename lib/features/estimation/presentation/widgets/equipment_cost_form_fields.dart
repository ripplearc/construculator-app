import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/choice_chip_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/rate_status_badge.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Inclusive bounds for a manually entered delivery fee, mirroring the daily
/// rate/job amount bounds enforced by [EquipmentCostFormBloc]. Zero is a
/// separate, always-valid value (confirmed-free) outside this range.
const double _minDeliveryFee = 0.01;
const double _maxDeliveryFee = 999999.99;

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

  /// Backs the "Save as my rate" link and the Rate/Amount field's
  /// look-up-a-rate search button. Injected rather than resolved with
  /// `Modular.get` here, since this widget isn't a module file.
  final YourRatesRepository yourRatesRepository;

  /// Builds a [YourRatesBloc] for the look-up-a-rate sheet — a new instance
  /// per open, matching [YourRatesBloc]'s factory registration.
  final YourRatesBloc Function() yourRatesBlocFactory;

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
    this.estimateId,
    required this.yourRatesRepository,
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

  /// Owns the Day/Job choice-chip selection. Exactly one of these is true at
  /// all times; kept as persistent notifiers (rather than derived fresh from
  /// bloc state on every build) so the chip's own tap-driven toggle can be
  /// corrected deterministically — see [_selectMethod].
  final _daySelected = ValueNotifier<bool>(true);
  final _jobSelected = ValueNotifier<bool>(false);

  /// Whether the delivery-fee panel (value field, status chrome, Note field)
  /// is open below its always-visible summary header. Toggled only by
  /// tapping the header or its chevron — see [_toggleDeliveryExpanded] —
  /// and, unlike an ordinary accordion, deliberately does NOT close when the
  /// value field loses focus: the Figma mock shows the panel staying open
  /// through typing, folding, and confirming, closing only on an explicit
  /// header tap.
  bool _deliveryExpanded = false;

  @override
  void initState() {
    super.initState();
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
    _notifyTotal();
  }

  void _onDailyRateChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentRateUpdatedEvent(_dailyRateController.text),
    );
    _notifyTotal();
  }

  void _onJobAmountChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentRateUpdatedEvent(_jobAmountController.text),
    );
    _notifyTotal();
  }

  void _onDeliveryFeeChanged() {
    context.read<EquipmentCostFormBloc>().add(
      EquipmentDeliveryFeeUpdatedEvent(_deliveryFeeController.text),
    );
    _notifyTotal();
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

  // "Add note" opens the panel (if closed) focused directly on the Note
  // field, rather than the delivery-value field [_toggleDeliveryExpanded]
  // focuses.
  void _openNoteField() {
    if (!_deliveryExpanded) {
      setState(() => _deliveryExpanded = true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _noteFocusNode.requestFocus();
    });
  }

  void _onConfirmDeliveryFee() {
    context.read<EquipmentCostFormBloc>().add(
      const EquipmentDeliveryFeeConfirmedEvent(),
    );
  }

  // Fires when the delivery-fee field folds (loses focus), which this widget
  // treats as "the user is done entering this value" for the outsized-fee
  // check below. Unlike the old collapsed/expanded toggle, folding no longer
  // closes the panel (see [_deliveryExpanded]'s doc comment) — this only
  // rebuilds so the Estimated/Confirm chrome (hidden while focused) appears.
  void _onDeliveryFocusChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_deliveryFocusNode.hasFocus) {
      unawaited(_maybeConfirmOutsizedFee());
    }
  }

  Future<void> _maybeConfirmOutsizedFee() async {
    final data = _dataOf(context.read<EquipmentCostFormBloc>().state);
    final fee = data.deliveryFee;
    if (fee == null) return;
    final isDay = data.method == EquipmentPricingMethod.day;
    final baseCost = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : (data.jobAmount ?? 0);
    // A base cost of 0 means duration/rate (or the job amount) hasn't been
    // entered yet, not that the fee is genuinely outsized — without a real
    // base cost there's nothing meaningful to compare against.
    if (baseCost <= 0) return;
    if (fee <= baseCost) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OutsizedFeeDialog(fee: fee, baseCost: baseCost),
    );
    if (!mounted) return;

    if (accepted == true) {
      // Real submission is still gated behind CA-355, so this currently
      // no-ops (the bloc only reacts to it from
      // EquipmentCostFormOutsizedFeeConfirm, a state this widget doesn't
      // drive the bloc into — see the class doc comment). Dispatched anyway
      // for forward compatibility once CA-355 wires up submission.
      context.read<EquipmentCostFormBloc>().add(
        EquipmentOutsizedFeeAcceptedEvent(estimateId: widget.estimateId ?? ''),
      );
    } else {
      // .clear() notifies _deliveryFeeController's listener, which already
      // dispatches EquipmentDeliveryFeeUpdatedEvent('') and calls
      // _notifyTotal() — see _onDeliveryFeeChanged.
      _deliveryFeeController.clear();
    }
  }

  // Tapping a chip re-drives both notifiers to `false`: ChoiceChipToggle
  // toggles its own `selected` notifier right after this callback returns,
  // so the tapped chip's notifier flips back to `true` on its own, while the
  // untapped sibling — never auto-toggled — is left `false`. This holds
  // regardless of which chip was active beforehand, so re-tapping the
  // already-active chip leaves the same chip selected.
  void _selectMethod(EquipmentPricingMethod tapped) {
    _daySelected.value = false;
    _jobSelected.value = false;
    context.read<EquipmentCostFormBloc>().add(
      EquipmentMethodSwitchedEvent(tapped),
    );
    _notifyTotal(tapped);
  }

  // TODO: [CA-353](https://ripplearc.youtrack.cloud/issue/CA-353) Move total calculation into BLoC when submission is wired
  void _notifyTotal([EquipmentPricingMethod? method]) {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final isDay =
        (method ??
            (_daySelected.value
                ? EquipmentPricingMethod.day
                : EquipmentPricingMethod.job)) ==
        EquipmentPricingMethod.day;
    final rawTotal = isDay
        ? (double.tryParse(_durationController.text) ?? 0) *
              (double.tryParse(_dailyRateController.text) ?? 0)
        : double.tryParse(_jobAmountController.text) ?? 0;
    final base = rawTotal.isFinite ? rawTotal : 0.0;
    final rawDelivery = double.tryParse(_deliveryFeeController.text) ?? 0;
    final delivery = rawDelivery.isFinite ? rawDelivery : 0.0;
    // Delivery is added after the rate math, never inside it.
    widget.onTotalChanged?.call(base + delivery);
  }

  EquipmentCostFormWithData _dataOf(EquipmentCostFormState state) =>
      switch (state) {
        EquipmentCostFormEditing(:final data) => data,
        EquipmentCostFormOutsizedFeeConfirm(:final data) => data,
        EquipmentCostFormSubmitting(:final data) => data,
        EquipmentCostFormSuccess(:final data) => data,
        EquipmentCostFormFailure(:final data) => data,
        EquipmentCostFormInitial() => const EquipmentCostFormWithData(),
      };

  List<String>? _errorList(String? text) => text == null ? null : [text];

  String? _durationErrorText(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    return data.fieldErrors['duration'] == 'durationRequired'
        ? context.l10n.equipmentDurationRequiredError
        : null;
  }

  String? _rateErrorText(BuildContext context, EquipmentCostFormWithData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors['dailyRate']) {
      'rateRequired' => l10n.equipmentRateRequiredError,
      'rateOutOfRange' => l10n.equipmentRateOutOfRangeError,
      _ => null,
    };
  }

  String? _amountErrorText(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    final l10n = context.l10n;
    return switch (data.fieldErrors['jobAmount']) {
      'rateRequired' => l10n.equipmentAmountRequiredError,
      'rateOutOfRange' => l10n.equipmentAmountOutOfRangeError,
      _ => null,
    };
  }

  // EquipmentCostFormBloc doesn't validate the delivery-fee bound (only item
  // type, duration, and dailyRate/jobAmount feed into its isValid/fieldErrors
  // — see the bloc's _validated). This check is done locally so it stays
  // purely advisory: it never blocks a keystroke or Save. Empty (unset) and
  // exactly 0 (confirmed-free) are both valid and never show this error.
  String? _deliveryFeeErrorText(BuildContext context) {
    final raw = _deliveryFeeController.text.trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null || value == 0) return null;
    if (value < _minDeliveryFee || value > _maxDeliveryFee) {
      return context.l10n.equipmentDeliveryFeeOutOfRangeError;
    }
    return null;
  }

  String _deliveryRowText(BuildContext context, double? fee) {
    final l10n = context.l10n;
    final value = fee == null
        ? l10n.equipmentDeliveryFeeUnsetText
        : DisplayFormatter.currency.format(fee);
    return '${l10n.equipmentDeliveryRowLabel} $value';
  }

  String? _deliveryStatusHelperText(
    BuildContext context,
    DeliveryFeeStatus status,
  ) {
    final l10n = context.l10n;
    return switch (status) {
      DeliveryFeeStatus.estimated =>
        l10n.equipmentDeliveryFeeEstimatedHelperText,
      DeliveryFeeStatus.confirmed =>
        l10n.equipmentDeliveryFeeConfirmedHelperText,
      DeliveryFeeStatus.unset => null,
    };
  }

  // Both variants map directly onto RateStatus; `missing` (no rate typed
  // yet) shows no badge at all — absence of a tag is itself the "no rate
  // yet" signal, matching the Figma component set (node 65685:147068).
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
      RateStatus.missing => null,
    };
  }

  YourRatesRepository get _yourRatesRepository => widget.yourRatesRepository;

  // No mechanism anywhere in this app resolves the caller's real company id
  // (no companyId on ProjectRepository/Project, no CurrentCompanyRepository).
  // Per YourRatesRepository.save's own doc comment, companyId only matters
  // for writes, which the backend validates against the caller's actual
  // company membership — an empty id fails that check server-side instead
  // of writing to the wrong company.
  // TODO: replace with a real company id once that resolution exists.
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

  Future<void> _saveAsMyRate(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) async {
    final result = await _yourRatesRepository.save(_buildYourRateEntry(data));
    if (!mounted) return;
    await result.fold((failure) async {
      if (failure is EstimationFailure &&
          failure.errorType == EstimationErrorType.duplicateEntry) {
        await _promptEntryLabelAndRetry(context, data);
        return;
      }
      _showSnack(context, context.l10n.yourRatesSaveFailedError);
    }, (_) async {});
  }

  Future<void> _promptEntryLabelAndRetry(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _EntryLabelDialog(),
    );
    if (label == null || !mounted) return;
    final result = await _yourRatesRepository.save(
      _buildYourRateEntry(data, entryLabel: label),
    );
    if (!mounted) return;
    result.fold(
      (_) => _showSnack(context, context.l10n.yourRatesSaveFailedError),
      (_) {},
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Shown for any rate the contractor hasn't yet saved to Your rates:
  // RateStatus.missing (nothing typed) shows the look-up-a-rate search
  // button instead — see the caller — so this only covers
  // ownRateConfirmed/sampleRateUnverified.
  Widget? _saveAsMyRateLink(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    if (data.rateStatus == RateStatus.missing) return null;
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
        onTap: () => unawaited(_saveAsMyRate(context, data)),
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

  // Figma node 65814:173685/173689: the "Set your rate" empty state has no
  // $ icon, only the search button below.
  Widget? _rateSuffixIcon(BuildContext context, RateStatus status) {
    if (status == RateStatus.missing) return null;
    final colorTheme = context.colorTheme;
    return CoreIconWidget(
      key: const Key('rate_dollar_icon'),
      icon: CoreIcons.dollar,
      color: colorTheme.textHeadline,
      size: 24,
    );
  }

  // Shown only while the field is empty — once a rate exists (typed or
  // picked), [_saveAsMyRateLink] takes this slot instead.
  Widget? _lookupRateButton(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    if (data.rateStatus != RateStatus.missing) return null;
    final colorTheme = context.colorTheme;
    return Semantics(
      button: true,
      label: context.l10n.yourRatesLookupButton,
      excludeSemantics: true,
      child: GestureDetector(
        key: const Key('lookup_rate_button'),
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(_openRateLookup(context, data.method)),
        child: Container(
          width: CoreSpacing.space10,
          height: CoreSpacing.space10,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colorTheme.textLink),
            borderRadius: BorderRadius.circular(CoreSpacing.space2),
          ),
          child: CoreIconWidget(
            icon: CoreIcons.search,
            color: colorTheme.iconGrayMid,
            size: 20,
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
    _equipmentNameController.text = entry.itemName;
    (method == EquipmentPricingMethod.day
            ? _dailyRateController
            : _jobAmountController)
        .text = entry.rate.amount
        .toString();
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
      BlocConsumer<EquipmentCostFormBloc, EquipmentCostFormState>(
        listener: (_, state) {
          widget.onSaveEnabledChanged?.call(_dataOf(state).isValid);
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
                controller: _equipmentNameController,
                errorTextList: data.itemTypeError != null
                    ? [l10n.equipmentNameRequiredError]
                    : null,
              ),
              const SizedBox(height: CoreSpacing.space5),
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
                  errorTextList: _errorList(_durationErrorText(context, data)),
                ),
                const SizedBox(height: CoreSpacing.space5),
                UnderlineTextField(
                  key: const Key('rate_field'),
                  label: l10n.equipmentRateLabel,
                  controller: _dailyRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  suffix: _rateSuffixIcon(context, data.rateStatus),
                  labelTrailing: _rateStatusBadge(context, data.rateStatus),
                  trailingAction:
                      _saveAsMyRateLink(context, data) ??
                      _lookupRateButton(context, data),
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
                  suffix: _rateSuffixIcon(context, data.rateStatus),
                  labelTrailing: _rateStatusBadge(context, data.rateStatus),
                  trailingAction:
                      _saveAsMyRateLink(context, data) ??
                      _lookupRateButton(context, data),
                  errorTextList: _errorList(_amountErrorText(context, data)),
                ),
              const SizedBox(height: CoreSpacing.space5),
              _buildDeliveryFeeSection(context, data),
            ],
          );
        },
      ),
    ];
  }

  // Delivery applies the same way under Day and Job pricing, so this row
  // sits below the if/else above rather than inside either branch.
  //
  // One persistent grey panel, not a collapsed-row/expanded-field swap: the
  // Figma mock (cuj6-equip-5c/5d/5h/5i) shows the "Delivery <value> · Add
  // note" header staying visible with its chevron pointed up through
  // typing, folding, and confirming — only an explicit tap on the header
  // closes it. See [_deliveryExpanded]'s doc comment.
  Widget _buildDeliveryFeeSection(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    // Hidden while the field has focus (mid-keystroke), matching the Figma
    // mock: the badge/link only appear once the value has folded.
    final showConfirmChrome =
        !_deliveryFocusNode.hasFocus &&
        data.deliveryFeeStatus == DeliveryFeeStatus.estimated;
    final helperText = _deliveryStatusHelperText(
      context,
      data.deliveryFeeStatus,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colorTheme.backgroundGrayLight,
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: _deliveryRowText(context, data.deliveryFee),
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: const Key('delivery_fee_row'),
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleDeliveryExpanded,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _deliveryRowText(context, data.deliveryFee),
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyLargeRegular.copyWith(
                                color: colorTheme.textHeadline,
                              ),
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: textTheme.bodyLargeRegular.copyWith(
                              color: colorTheme.textHeadline,
                            ),
                          ),
                        ],
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
                      style: textTheme.bodyLargeRegular.copyWith(
                        color: colorTheme.textLink,
                      ),
                    ),
                  ),
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
                        icon: CoreIcons.arrowDropDown,
                        color: colorTheme.iconGrayMid,
                        size: 24,
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
              prefix: CoreIconWidget(
                icon: CoreIcons.dollar,
                color: colorTheme.textHeadline,
                size: 24,
              ),
              labelTrailing: showConfirmChrome
                  ? RateStatusBadge(
                      key: const Key('delivery_fee_estimated_badge'),
                      label: l10n.equipmentDeliveryFeeEstimatedBadge,
                      variant: RateStatusBadgeVariant.orange,
                    )
                  : null,
              trailingAction: showConfirmChrome
                  ? Semantics(
                      button: true,
                      label: l10n.equipmentDeliveryFeeConfirmLink,
                      excludeSemantics: true,
                      child: GestureDetector(
                        key: const Key('delivery_fee_confirm_link'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _onConfirmDeliveryFee,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          alignment: Alignment.centerRight,
                          child: Text(
                            l10n.equipmentDeliveryFeeConfirmLink,
                            style: textTheme.bodySmallSemiBold.copyWith(
                              color: colorTheme.textLink,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              errorTextList: _errorList(_deliveryFeeErrorText(context)),
            ),
            if (helperText != null) ...[
              const SizedBox(height: CoreSpacing.space2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoreIconWidget(
                    icon: CoreIcons.info,
                    color: colorTheme.iconGrayMid,
                    size: 16,
                  ),
                  const SizedBox(width: CoreSpacing.space1),
                  Expanded(
                    child: Text(
                      helperText,
                      key: data.deliveryFeeStatus == DeliveryFeeStatus.confirmed
                          ? const Key('delivery_fee_confirmed_helper_text')
                          : const Key('delivery_fee_estimated_helper_text'),
                      style: textTheme.bodySmallRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

/// Confirmation dialog shown when a just-entered delivery fee exceeds this
/// line's own computed base cost (duration × dailyRate under Day pricing, or
/// jobAmount under Job pricing).
///
/// Modeled on Figma's generic "Confirmation Dialog" component (node
/// 65354:146175), also used elsewhere for an unrelated archive-confirmation
/// flow: 340×262, 20px corner radius, 22px padding, 12px gap, a 52×52 light
/// blue icon circle, an 18px semibold title, a 14px regular body, and a
/// secondary/primary [CoreButton] pair.
///
/// The title/body copy below is PLACEHOLDER TEXT pending design sign-off:
/// neither the design doc nor the storyboard specifies exact strings for
/// this dialog (CA-1144). Swap the equipmentDeliveryFeeOutsizedDialogTitle/
/// Body ARB entries once real copy is approved.
class _OutsizedFeeDialog extends StatelessWidget {
  const _OutsizedFeeDialog({required this.fee, required this.baseCost});

  final double fee;
  final double baseCost;

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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorTheme.backgroundBlueLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CoreIconWidget(
                    icon: CoreIcons.info,
                    color: colorTheme.iconBlue,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Text(
                l10n.equipmentDeliveryFeeOutsizedDialogTitle,
                key: const Key('outsized_fee_dialog_title'),
                style: textTheme.titleMediumSemiBold.copyWith(
                  color: colorTheme.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space3),
              Text(
                l10n.equipmentDeliveryFeeOutsizedDialogBody(
                  DisplayFormatter.currency.format(fee),
                  DisplayFormatter.currency.format(baseCost),
                ),
                key: const Key('outsized_fee_dialog_body'),
                style: textTheme.bodyMediumRegular.copyWith(
                  color: colorTheme.textBody,
                ),
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
