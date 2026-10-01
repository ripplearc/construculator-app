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
import 'package:construculator/libraries/time/interfaces/clock.dart';
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

  /// Builds a [YourRatesBloc] backing the "Save as my rate" link and the
  /// Rate/Amount field's look-up-a-rate search button. Injected rather than
  /// resolved with `Modular.get` here, since this widget isn't a module
  /// file. Called twice: once for the bloc this widget owns for saves (see
  /// [_EquipmentCostFormFieldsState]'s own instance), and once per
  /// look-up-a-rate sheet open, matching [YourRatesBloc]'s factory
  /// registration.
  final YourRatesBloc Function() yourRatesBlocFactory;

  /// Supplies "now" for a saved [YourRateEntry]'s timestamp — see [Clock]'s
  /// own doc comment for why this is injected rather than calling
  /// [DateTime.now] directly.
  final Clock clock;

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
    this.estimateId,
    required this.yourRatesBlocFactory,
    required this.clock,
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

  // Fires when the delivery-fee field folds (loses focus). This only
  // rebuilds so the Estimated/Confirm chrome (hidden while focused)
  // appears — it no longer triggers the outsized-fee dialog itself; see
  // [maybeConfirmOutsizedFee]'s doc comment for why that check moved off
  // focus loss.
  void _onDeliveryFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Runs the outsized-fee confirmation flow for the currently entered
  /// delivery fee, showing [_OutsizedFeeDialog] when the fee exceeds this
  /// line's own base cost. Returns whether the caller should proceed with
  /// submission: true when there's nothing to confirm (no fee entered, the
  /// fee isn't outsized, or the user tapped "Add it"/dismissed the dialog
  /// to accept it anyway); false when the user chose "Go back" (or tapped
  /// outside the dialog, which the dialog treats the same way — see
  /// [_OutsizedFeeDialog]) and submission should not proceed.
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
    return data.fieldErrors['duration'] == 'durationInvalid'
        ? context.l10n.equipmentDurationInvalidError
        : null;
  }

  String? _rateErrorText(BuildContext context, EquipmentCostFormWithData data) {
    final l10n = context.l10n;
    return switch (data.fieldErrors['dailyRate']) {
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
      'rateOutOfRange' => l10n.equipmentAmountOutOfRangeError,
      _ => null,
    };
  }

  String? _deliveryFeeErrorText(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    return data.fieldErrors['deliveryFee'] == 'deliveryFeeOutOfRange'
        ? context.l10n.equipmentDeliveryFeeOutOfRangeError
        : null;
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

  // No mechanism anywhere in this app resolves the caller's real company id
  // (no companyId on ProjectRepository/Project, no CurrentCompanyRepository).
  // Per YourRatesRepository.save's own doc comment, companyId only matters
  // for writes, which the backend validates against the caller's actual
  // company membership — an empty id fails that check server-side instead
  // of writing to the wrong company.
  // TODO: [CA-1180](https://ripplearc.youtrack.cloud/issue/CA-1180) Replace
  // this stub with a real company id from CurrentCompanyResolver — CA-1180
  // owns updating this call site specifically, once CurrentCompanyResolver
  // itself (CA-1179, a CA-1180 dependency) exists.
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
      savedAt: widget.clock.now(),
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
    final l10n = context.l10n;
    switch (state) {
      case YourRatesSaveCollision(:final entry):
        unawaited(_promptEntryLabelAndRetry(context, entry));
      // TODO: CA-1207 — every YourRatesSaveFailed shows this same generic
      // message, even though YourRatesRepositoryImpl._handleError already
      // distinguishes timeoutError/connectionError/parsingError/
      // permissionDenied/notFoundError. Needs that EstimationErrorType
      // threaded through this state and distinct, actionable copy per type.
      case YourRatesSaveFailed():
        CoreToast.showError(
          context,
          l10n.yourRatesSaveFailedError,
          l10n.closeLabel,
        );
      case YourRatesSaveSucceeded():
        CoreToast.showSuccess(
          context,
          l10n.yourRatesSaveSucceededMessage,
          l10n.closeLabel,
        );
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

  // True when the rate/amount field currently in play (Day pricing reads
  // dailyRate, Job pricing reads jobAmount) has a validation error. Checked
  // by [_offersSaveAsMyRate] alongside [EquipmentCostFormWithData.itemTypeError]
  // so the link can't fire a save built from an equipment name or rate the
  // form itself is showing red.
  bool _hasRateFieldError(EquipmentCostFormWithData data) {
    final key = data.method == EquipmentPricingMethod.day
        ? 'dailyRate'
        : 'jobAmount';
    return data.fieldErrors.containsKey(key);
  }

  // Shared gate for [_saveAsMyRateLink] and [_saveAsMyRateHelperText], which
  // always appear together (Figma node 66342:178091's "Buttons" link and its
  // "Ic_Info_16x16" + text row right below it). True for a rate the
  // contractor hasn't yet saved to Your rates: RateStatus.missing (nothing
  // typed) shows the look-up-a-rate search button instead — see the caller —
  // and RateStatus.ownRateConfirmed (recalled from Your Rates, CUJ 6
  // Sub-flows B/C) is already saved there, so re-offering to save it again
  // is redundant — so this only covers sampleRateUnverified/
  // ownRateUnconfirmed. Also false while the rate/amount field itself has a
  // validation error, so neither the link nor the helper text can offer to
  // save an out-of-range rate.
  //
  // `data.itemTypeError` is checked too, but per EquipmentCostFormBloc's own
  // field-error policy (see its `_validated` doc comment) an empty item type
  // never populates fieldErrors — only a present-but-unusable value does —
  // so that check alone never actually excludes a blank name. The
  // controller-text check below is what really does that job, reading
  // straight from the same controller [_buildYourRateEntry] uses to build
  // `itemName`, so the two can never disagree about what "empty" means.
  bool _offersSaveAsMyRate(EquipmentCostFormWithData data) =>
      (data.rateStatus == RateStatus.sampleRateUnverified ||
          data.rateStatus == RateStatus.ownRateUnconfirmed) &&
      data.itemTypeError == null &&
      _equipmentNameController.text.trim().isNotEmpty &&
      !_hasRateFieldError(data);

  Widget? _saveAsMyRateLink(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    if (!_offersSaveAsMyRate(data)) return null;
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    // TODO: CA-1207 — nothing on screen changes between this tap and the
    // eventual success/failure toast. The _droppable() transformer on
    // YourRatesSaveRequested already stops a double-tap from double-saving,
    // but gives no visual confirmation the first tap registered.
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

  // "/day" for Day pricing, "job" for Job — the Rate/Amount field's own unit
  // suffix (Figma's "Text Field" component instances for both fields set
  // `Field unit`/`Show field unit`, mirroring the Duration field's "days"
  // suffix just above it). Reuses yourRatesDaySuffix/yourRatesJobSuffix
  // rather than adding a duplicate string, since the Look-up-a-rate sheet's
  // "Use $520.00 job" button already established this exact Day/Job
  // vocabulary.
  String _rateUnitSuffix(BuildContext context, EquipmentPricingMethod method) {
    final l10n = context.l10n;
    return method == EquipmentPricingMethod.day
        ? l10n.yourRatesDaySuffix
        : l10n.yourRatesJobSuffix;
  }

  // Explanatory row (info icon + text) directly below the Rate/Amount field,
  // shown only alongside [_saveAsMyRateLink] (Figma node 66342:178091's
  // "Ic_Info_16x16" + text instances at y=442-443, right under the "Save as
  // my default" link). Styled like [_buildDeliveryFeeSection]'s own helper
  // text row — the established pattern in this file for a 16px info icon
  // plus bodySmallRegular/textBody text.
  Widget? _saveAsMyRateHelperText(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    if (!_offersSaveAsMyRate(data)) return null;
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isDay = data.method == EquipmentPricingMethod.day;
    final amount = DisplayFormatter.currency.format(
      (isDay ? data.dailyRate : data.jobAmount) ?? 0,
    );
    return Padding(
      padding: const EdgeInsets.only(top: CoreSpacing.space2),
      child: Row(
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
              l10n.equipmentSaveAsMyRateHelperText(
                amount,
                _rateUnitSuffix(context, data.method),
                data.equipmentType,
              ),
              key: const Key('save_as_my_rate_helper_text'),
              style: textTheme.bodySmallRegular.copyWith(
                color: colorTheme.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _lookupRateButtonWhenEmpty(
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
    // Setting these controllers' text fires their own listeners first
    // (EquipmentCostItemTypeChanged, EquipmentRateUpdatedEvent), which would
    // mark the rate ownRateUnconfirmed like any other typed value. The
    // EquipmentSavedRateRecalledEvent dispatched below runs after both, on
    // the same synchronous event queue, so it's what the bloc's state
    // actually settles on: equipmentType/method/rate set again, this time
    // with RateStatus.ownRateConfirmed — CUJ 6 Sub-flows B/C's "already
    // verified, no verification step" rate.
    _equipmentNameController.text = entry.itemName;
    (method == EquipmentPricingMethod.day
            ? _dailyRateController
            : _jobAmountController)
        .text = _formatTrimmedNumber(
      entry.rate.amount,
    );
    context.read<EquipmentCostFormBloc>().add(
      EquipmentSavedRateRecalledEvent(
        equipmentType: entry.itemName,
        method: method,
        rate: entry.rate.amount,
      ),
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

  // Figma's "How many days?" field (B2, node 66337:158600) and the Duration
  // field above (the full, not-yet-recalled form) are the same control —
  // same controller, same validation — so this is shared between both
  // layouts rather than duplicated.
  Widget _durationField(BuildContext context, EquipmentCostFormWithData data) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return UnderlineTextField(
      key: const Key('duration_field'),
      label: l10n.equipmentDurationLabel,
      hintText: l10n.equipmentDurationPlaceholder,
      controller: _durationController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffix: Text(
        l10n.equipmentDurationSuffix,
        style: textTheme.bodyMediumRegular.copyWith(color: colorTheme.textBody),
      ),
      errorTextList: _errorList(_durationErrorText(context, data)),
    );
  }

  // Shared between the full form's Amount field and C2's recalled-job-price
  // confirmation (node 66337:159434) — same controller, same validation.
  // [showRateChrome] is false for C2, which per Figma shows none of the
  // rate-status badge, "Save as my default" link, or look-up-a-rate button
  // a not-yet-recalled Amount field offers.
  Widget _amountField(
    BuildContext context,
    EquipmentCostFormWithData data, {
    bool showRateChrome = true,
  }) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return UnderlineTextField(
      key: const Key('amount_field'),
      label: l10n.equipmentAmountLabel,
      controller: _jobAmountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffix: Text(
        _rateUnitSuffix(context, data.method),
        style: textTheme.bodyMediumRegular.copyWith(color: colorTheme.textBody),
      ),
      labelTrailing: showRateChrome
          ? _rateStatusBadge(context, data.rateStatus)
          : null,
      trailingAction: showRateChrome
          ? (_saveAsMyRateLink(context, data) ??
                _lookupRateButtonWhenEmpty(context, data))
          : null,
      errorTextList: _errorList(_amountErrorText(context, data)),
    );
  }

  // Title (equipment name) + subtitle (saved rate, e.g. "$120.00 /day · your
  // default") standing in for the full name field/rate field/badge once a
  // rate is recalled from Your Rates — Figma's B2/C2 confirmation header
  // (nodes 66337:158600/66337:159434), not the screen's own CoreAppBar
  // title, which stays the fixed "Add equipment costs" string.
  List<Widget> _recalledRateHeader(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isDay = data.method == EquipmentPricingMethod.day;
    final amount = DisplayFormatter.currency.format(
      (isDay ? data.dailyRate : data.jobAmount) ?? 0,
    );
    return [
      Text(
        data.equipmentType,
        key: const Key('recalled_rate_title'),
        style: textTheme.titleMediumSemiBold.copyWith(
          color: colorTheme.textHeadline,
        ),
      ),
      const SizedBox(height: CoreSpacing.space1),
      Text(
        l10n.equipmentRecalledRateSubtitle(
          amount,
          _rateUnitSuffix(context, data.method),
        ),
        key: const Key('recalled_rate_subtitle'),
        style: textTheme.bodyMediumRegular.copyWith(
          color: colorTheme.textBody,
        ),
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
            widget.onSaveEnabledChanged?.call(data.isValid);
            // The bloc is the only owner of the Day/Job choice; mirror it
            // into the chip notifiers here so a method change from any
            // source (not just a tap on these two chips) keeps both chips
            // in sync with it.
            _daySelected.value = data.method == EquipmentPricingMethod.day;
            _jobSelected.value = data.method == EquipmentPricingMethod.job;
          },
          builder: (_, state) {
            final data = _dataOf(state);
            final isDay = data.method == EquipmentPricingMethod.day;
            // CUJ 6 Sub-flows B/C: once a rate is recalled from Your Rates
            // it's already verified, so Figma swaps the full entry form for
            // a compact confirmation — name/rate become a read-only
            // Title/Subtitle and only Duration (Day) or Amount (Job) stays
            // editable. No equipment-name field, Day/Job toggle,
            // rate-status badge, "Save as my default" link, or
            // look-up-a-rate button on this screen (see
            // _recalledRateHeader/_amountField's own doc comments).
            if (data.rateStatus == RateStatus.ownRateConfirmed) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._recalledRateHeader(context, data),
                  const SizedBox(height: CoreSpacing.space5),
                  isDay
                      ? _durationField(context, data)
                      : _amountField(context, data, showRateChrome: false),
                  const SizedBox(height: CoreSpacing.space5),
                  _buildDeliveryFeeSection(context, data),
                ],
              );
            }
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
                  _durationField(context, data),
                  const SizedBox(height: CoreSpacing.space5),
                  UnderlineTextField(
                    key: const Key('rate_field'),
                    label: l10n.equipmentRateLabel,
                    controller: _dailyRateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    suffix: Text(
                      _rateUnitSuffix(context, data.method),
                      style: textTheme.bodyMediumRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                    labelTrailing: _rateStatusBadge(context, data.rateStatus),
                    trailingAction:
                        _saveAsMyRateLink(context, data) ??
                        _lookupRateButtonWhenEmpty(context, data),
                    errorTextList: _errorList(_rateErrorText(context, data)),
                  ),
                  _saveAsMyRateHelperText(context, data) ??
                      const SizedBox.shrink(),
                ] else ...[
                  _amountField(context, data),
                  _saveAsMyRateHelperText(context, data) ??
                      const SizedBox.shrink(),
                ],
                const SizedBox(height: CoreSpacing.space5),
                _buildDeliveryFeeSection(context, data),
              ],
            );
          },
        ),
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
              errorTextList: _errorList(_deliveryFeeErrorText(context, data)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final isDay = method == EquipmentPricingMethod.day;
    final bodyText = isDay
        ? l10n.equipmentDeliveryFeeOutsizedDialogBodyDay(
            DisplayFormatter.currency.format(fee),
            _formatTrimmedNumber(duration ?? 0),
            equipmentType.trim().isEmpty
                ? l10n.equipmentDeliveryFeeOutsizedDialogGenericItem
                : equipmentType.trim(),
            DisplayFormatter.currency.format(baseCost),
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

/// Prompts for the freeform label required to save a rate that collides
/// with an existing "Your rates" entry for the same equipment (Decision 55):
/// [YourRatesRepository.save] rejects an unlabeled save into an
/// already-populated (companyId, category, itemName) grouping rather than
/// guessing which row to overwrite.
///
/// Returns the typed label via `Navigator.pop`, or null if cancelled.
///
/// Shares [_OutsizedFeeDialog]'s 340-wide "Confirmation Dialog" shell
/// (Figma node 65354:146175) — see that class's doc comment for the full
/// component spec. Unlike that class, this one's padding uses
/// [CoreSpacing.space6] rather than repeating the same literal 22px value —
/// see the comment above the `Padding` below for why.
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
      // CoreSpacing has no token that lands exactly on _OutsizedFeeDialog's
      // literal 22px padding (space5=20, space6=24 — both 2px off), so this
      // dialog uses the nearest token, space6, instead of also hardcoding
      // 22. The 340 width just below has no spacing-token equivalent at
      // all (it isn't a padding/gap value), so it stays literal.
      child: Padding(
        padding: const EdgeInsets.all(CoreSpacing.space6),
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
