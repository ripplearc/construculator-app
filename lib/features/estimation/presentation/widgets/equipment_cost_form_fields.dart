import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/your_rates_bloc/your_rates_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/choice_chip_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/rate_status_badge.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
import 'package:construculator/features/estimation/presentation/widgets/your_rates_lookup_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Strips a trailing ".0" from a whole number (e.g. `4.0` -> `"4"`) but
/// keeps a fractional value as typed (e.g. `4.5` -> `"4.5"`). For numeric
/// text fields, which expect a plain typed-style number rather than one
/// formatted for display — a duration named in dialog copy, or a rate
/// amount picked from Your rates.
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

  /// Builds a [YourRatesBloc] for the Rate/Amount field's look-up-a-rate
  /// search button. Injected rather than resolved with `Modular.get` here,
  /// since this widget isn't a module file. Called once per look-up-a-rate
  /// sheet open, matching [YourRatesBloc]'s factory registration.
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
      EquipmentCostFormFieldsState();
}

/// Public so a future caller can reach [maybeConfirmOutsizedFee] via
/// `GlobalKey<EquipmentCostFormFieldsState>` — see that method's doc
/// comment for why nothing calls it yet.
class EquipmentCostFormFieldsState extends State<EquipmentCostFormFields> {
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

  // Rebuilds so the delivery row header switches between the raw typed
  // digits (focused) and the two-decimal formatted value (folded) — see
  // _deliveryRowText.
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

  /// Runs the outsized-fee confirmation flow for the currently entered
  /// delivery fee, showing [_OutsizedFeeDialog] when the fee exceeds this
  /// line's own base cost. Returns whether the caller should proceed with
  /// submission: true when there's nothing to confirm (no fee entered or
  /// the fee isn't outsized) or the user tapped "Add it"; false when the
  /// user chose "Go back", or dismissed the dialog by tapping outside it
  /// (which the dialog treats the same as "Go back" — see
  /// [_OutsizedFeeDialog]), and submission should not proceed.
  ///
  /// Intentionally NOT wired to anything in this tree yet: the spec calls
  /// for this to run when the user taps "Add to estimate", not when the
  /// delivery field loses focus (the previous, incorrect trigger). That
  /// button — `add_to_cost_button` in `CostItemFormScreen` — is still a
  /// no-op `onPressed: () {}` stub pending CA-355's real submit flow, and
  /// it's shared across all three cost item types (Material/Labor/
  /// Equipment), so it has no access to this equipment-specific state
  /// today. CA-355's implementer should reach this method — e.g. via
  /// `GlobalKey<EquipmentCostFormFieldsState>` — from that handler before
  /// actually submitting.
  // TODO: [CA-355] wire this from the real "Add to estimate" handler. https://ripplearc.youtrack.cloud/issue/CA-355
  Future<bool> maybeConfirmOutsizedFee() async {
    final data = _dataOf(context.read<EquipmentCostFormBloc>().state);
    final fee = data.deliveryFee;
    if (fee == null) return true;
    final isDay = data.method == EquipmentPricingMethod.day;
    final baseCost = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : (data.jobAmount ?? 0);
    // A base cost of 0 means duration/rate (or the job amount) hasn't been
    // entered yet, not that the fee is genuinely outsized — without a real
    // base cost there's nothing meaningful to compare against.
    if (baseCost <= 0) return true;
    if (fee <= baseCost) return true;

    final accepted = await showDialog<bool>(
      context: context,
      // Tapping outside the dialog must behave like "Go back" (decline),
      // not like a no-op: barrierDismissible lets that tap pop the route
      // with a null result, which the `accepted != true` branch below
      // already treats the same as an explicit decline.
      barrierDismissible: true,
      builder: (_) => _OutsizedFeeDialog(
        fee: fee,
        baseCost: baseCost,
        method: data.method,
        duration: data.duration,
        equipmentType: data.equipmentType,
      ),
    );
    if (!mounted) return false;

    if (accepted == true) {
      final estimateId = widget.estimateId;
      // Real submission is still gated behind CA-355, so this currently
      // no-ops (the bloc only reacts to it from
      // EquipmentCostFormOutsizedFeeConfirm, a state this widget doesn't
      // drive the bloc into — see the class doc comment). Dispatched anyway
      // for forward compatibility once CA-355 wires up submission; skipped
      // entirely without an estimateId rather than sending an empty one.
      if (estimateId != null) {
        context.read<EquipmentCostFormBloc>().add(
          EquipmentOutsizedFeeAcceptedEvent(estimateId: estimateId),
        );
      }
      return true;
    }
    // "Go back" (or dismissing the barrier) must preserve the typed fee —
    // the panel stays open, the value stays put and editable — rather than
    // deleting it, so the controller is deliberately left untouched here.
    // Per the storyboard ("the fee is selected and the pad is up"), also
    // return focus to the field with its value selected, ready to retype.
    _deliveryFocusNode.requestFocus();
    _deliveryFeeController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _deliveryFeeController.text.length,
    );
    return false;
  }

  void _selectMethod(EquipmentPricingMethod tapped) {
    _daySelected.value = false;
    _jobSelected.value = false;
    context.read<EquipmentCostFormBloc>().add(
      EquipmentMethodSwitchedEvent(tapped),
    );
  }

  // Only reached in fromCostFile mode: the quantity field there never drives
  // a real total, and a fromCostFile toggle is a widget prop change, not a
  // bloc event, so the BlocConsumer listener below won't fire for it on its
  // own.
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
  //
  // Reads from the bloc's validated data rather than the raw controller
  // text, so an invalid duration/rate (or a Day/Job switch) can never
  // multiply into a total the form itself says is wrong.
  void _notifyTotalFromData(EquipmentCostFormData data) {
    final isDay = data.method == EquipmentPricingMethod.day;
    final hasFieldError = isDay
        ? data.fieldErrors.containsKey('duration') ||
              data.fieldErrors.containsKey('dailyRate')
        : data.fieldErrors.containsKey('jobAmount');
    if (hasFieldError) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final base = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : data.jobAmount ?? 0;
    final hasDeliveryFeeError = data.fieldErrors.containsKey('deliveryFee');
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
    return switch (data.fieldErrors['duration']) {
      'durationNotPositive' => l10n.equipmentDurationNotPositiveError,
      'durationNotHalfDay' => l10n.equipmentDurationNotHalfDayError,
      'durationTooLarge' => l10n.equipmentDurationTooLargeError,
      _ => null,
    };
  }

  String? _rateErrorText(BuildContext context, EquipmentCostFormData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors['dailyRate']) {
      'rateOutOfRange' => l10n.equipmentRateOutOfRangeError,
      _ => null,
    };
  }

  String? _amountErrorText(BuildContext context, EquipmentCostFormData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors['jobAmount']) {
      'rateOutOfRange' => l10n.equipmentAmountOutOfRangeError,
      _ => null,
    };
  }

  // Shows the raw typed digits while the field has focus (so the row header
  // and the field itself never disagree mid-keystroke, e.g. both read "85"
  // rather than the row jumping ahead to "$85.00"), and the two-decimal
  // formatted value once the field folds.
  String _deliveryRowText(BuildContext context, double? fee) {
    final l10n = context.l10n;
    final raw = _deliveryFeeController.text;
    final value = switch ((_deliveryFocusNode.hasFocus, raw.isEmpty, fee)) {
      (true, false, _) => raw,
      (_, _, null) => l10n.equipmentDeliveryFeeUnsetText,
      (_, _, final fee?) => DisplayFormatter.currency.format(fee),
    };
    return '${l10n.equipmentDeliveryRowLabel} $value';
  }

  // The two badge variants map onto sampleRateUnverified/ownRateConfirmed
  // only. `ownRateUnconfirmed` — a value just typed in, not yet confirmed
  // as the user's own rate (see that enum value's own doc comment) — and
  // `missing` (no rate typed yet) both show no badge at all: absence of a
  // tag is itself the "not confirmed yet" signal, matching the Figma
  // component set (node 65685:147068), which has no "in-progress" variant.
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

  // Only offered for a sample rate — once a value is typed in, it's already
  // either RateStatus.ownRateUnconfirmed (the only non-missing status the
  // bloc's rate-update handler sets today) or, once CA-1151's "save as my
  // rate" wiring lands, RateStatus.ownRateConfirmed; either way it's
  // already the user's own value, so offering to save it again is
  // redundant. No code path sets sampleRateUnverified yet (that's the
  // lookup-a-rate flow, also CA-1151), so this link renders correctly for
  // that future state without being exercisable today.
  Widget? _saveAsMyRateLink(BuildContext context, RateStatus status) {
    if (status != RateStatus.sampleRateUnverified) return null;
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
        // TODO: [CA-1151] wire to YourRatesRepository.save() once it exists. https://ripplearc.youtrack.cloud/issue/CA-1151
        onTap: () {},
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
      BlocConsumer<EquipmentCostFormBloc, EquipmentCostFormState>(
        listener: (_, state) {
          final data = _dataOf(state);
          widget.onSaveEnabledChanged?.call(data.isValid);
          _mirrorMethodIntoChips(data.method);
          if (!widget.fromCostFile) {
            _notifyTotalFromData(data);
          }
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
                  labelTrailing: _rateStatusBadge(context, data.rateStatus),
                  trailingAction:
                      _saveAsMyRateLink(context, data.rateStatus) ??
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
                      _saveAsMyRateLink(context, data.rateStatus) ??
                      _lookupRateButtonWhenEmpty(context, data),
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
    EquipmentCostFormData data,
  ) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space3,
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
/// The title/body copy matches the storyboard frame "Delivery $8500"
/// ("Delivery costs more than the machine" / "Delivery is {fee} against
/// {baseCost} for {duration} of {equipment}. Add it anyway?"). The
/// storyboard spells its one example duration as a word ("four days");
/// this uses digits instead so arbitrary durations don't need a
/// number-to-words conversion — flagging that choice for the owner to
/// override if the word form matters.
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

  /// Which pricing method [baseCost] was computed from — the dialog body
  /// names the time period (e.g. "4 days of excavator") for Day pricing,
  /// matching the storyboard, and omits it for Job pricing, where there's
  /// no duration to name.
  final EquipmentPricingMethod method;

  /// Entered duration, only meaningful (and only read) under Day pricing.
  final double? duration;

  /// Entered equipment name, only read under Day pricing to name the
  /// item in the body text; falls back to a generic noun when blank.
  final String equipmentType;

  // "1 day"/"half a day"/"N days" — the storyboard names a single day and a
  // half day specially; everything else stays in digit form (see this
  // class's doc comment for why digits rather than spelled-out numbers).
  String _formatDurationPhrase(BuildContext context, double value) {
    final l10n = context.l10n;
    if (value == 1) return l10n.equipmentDeliveryFeeOutsizedDialogOneDay;
    if (value == 0.5) return l10n.equipmentDeliveryFeeOutsizedDialogHalfDay;
    return l10n.equipmentDeliveryFeeOutsizedDialogDurationDays(
      _formatTrimmedNumber(value),
    );
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
                bodyText,
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
