import 'dart:async';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/choice_chip_toggle.dart';
import 'package:construculator/features/estimation/presentation/widgets/underline_text_field.dart';
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

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
    this.estimateId,
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

  /// Owns the Day/Job choice-chip selection. Exactly one of these is true at
  /// all times; kept as persistent notifiers (rather than derived fresh from
  /// bloc state on every build) so the chip's own tap-driven toggle can be
  /// corrected deterministically — see [_selectMethod].
  final _daySelected = ValueNotifier<bool>(true);
  final _jobSelected = ValueNotifier<bool>(false);

  /// Whether the delivery-fee row is showing its editable field (true) or its
  /// collapsed grey summary (false). Driven by tapping the collapsed row and
  /// by the field losing focus; see [_toggleDeliveryExpanded] and
  /// [_onDeliveryFocusChanged].
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

  void _toggleDeliveryExpanded() {
    if (_deliveryExpanded) {
      _deliveryFocusNode.unfocus();
      return;
    }
    setState(() => _deliveryExpanded = true);
    // CoreTextField has no autofocus param, so the field must exist in the
    // tree (post-frame) before it can accept focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _deliveryFocusNode.requestFocus();
    });
  }

  void _onConfirmDeliveryFee() {
    context.read<EquipmentCostFormBloc>().add(
      const EquipmentDeliveryFeeConfirmedEvent(),
    );
  }

  // Fires when the delivery-fee field folds (loses focus), which this widget
  // treats as "the user is done entering this value" — see the outsized-fee
  // check below.
  void _onDeliveryFocusChanged() {
    if (_deliveryFocusNode.hasFocus) return;
    if (!mounted) return;
    setState(() => _deliveryExpanded = false);
    unawaited(_maybeConfirmOutsizedFee());
  }

  Future<void> _maybeConfirmOutsizedFee() async {
    final data = _dataOf(context.read<EquipmentCostFormBloc>().state);
    final fee = data.deliveryFee;
    if (fee == null) return;
    final isDay = data.method == EquipmentPricingMethod.day;
    final baseCost = isDay
        ? (data.duration ?? 0) * (data.dailyRate ?? 0)
        : (data.jobAmount ?? 0);
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
                  suffix: CoreIconWidget(
                    icon: CoreIcons.dollar,
                    color: colorTheme.textHeadline,
                    size: 24,
                  ),
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
                  suffix: CoreIconWidget(
                    icon: CoreIcons.dollar,
                    color: colorTheme.textHeadline,
                    size: 24,
                  ),
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
  Widget _buildDeliveryFeeSection(
    BuildContext context,
    EquipmentCostFormWithData data,
  ) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_deliveryExpanded)
          CoreTextField(
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
            errorTextList: _errorList(_deliveryFeeErrorText(context)),
          )
        else
          Semantics(
            button: true,
            label: _deliveryRowText(context, data.deliveryFee),
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('delivery_fee_row'),
              onTap: _toggleDeliveryExpanded,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CoreSpacing.space4,
                  vertical: CoreSpacing.space3,
                ),
                decoration: BoxDecoration(
                  color: colorTheme.backgroundGrayLight,
                  borderRadius: BorderRadius.circular(CoreSpacing.space2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _deliveryRowText(context, data.deliveryFee),
                      style: textTheme.bodyLargeRegular.copyWith(
                        color: colorTheme.textHeadline,
                      ),
                    ),
                    CoreIconWidget(
                      icon: CoreIcons.arrowDropDown,
                      color: colorTheme.iconGrayMid,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (!_deliveryExpanded &&
            data.deliveryFeeStatus == DeliveryFeeStatus.estimated)
          _buildDeliveryEstimatedRow(context),
        if (!_deliveryExpanded &&
            data.deliveryFeeStatus == DeliveryFeeStatus.confirmed)
          _buildDeliveryConfirmedHelperText(context),
      ],
    );
  }

  Widget _buildDeliveryEstimatedRow(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: CoreSpacing.space2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('delivery_fee_estimated_badge'),
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space2,
              vertical: CoreSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: colorTheme.backgroundOrangeLight,
              borderRadius: BorderRadius.circular(CoreSpacing.space1),
            ),
            child: Text(
              l10n.equipmentDeliveryFeeEstimatedBadge,
              // textWarning-on-backgroundOrangeLight falls short of the 4.5:1
              // WCAG AA ratio at this text size; textHeadline clears it while
              // the amber fill still carries the "estimated" cue.
              style: textTheme.bodySmallMedium.copyWith(
                color: colorTheme.textHeadline,
              ),
            ),
          ),
          const SizedBox(width: CoreSpacing.space3),
          Semantics(
            button: true,
            label: l10n.equipmentDeliveryFeeConfirmLink,
            excludeSemantics: true,
            child: GestureDetector(
              key: const Key('delivery_fee_confirm_link'),
              behavior: HitTestBehavior.opaque,
              onTap: _onConfirmDeliveryFee,
              // Padded to a >=48x48 tap target per accessibility guidelines
              // without inflating the link's visible size.
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.equipmentDeliveryFeeConfirmLink,
                  style: textTheme.bodySmallSemiBold.copyWith(
                    color: colorTheme.textLink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryConfirmedHelperText(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: CoreSpacing.space2),
      child: Text(
        l10n.equipmentDeliveryFeeConfirmedHelperText,
        key: const Key('delivery_fee_confirmed_helper_text'),
        style: textTheme.bodySmallRegular.copyWith(color: colorTheme.textBody),
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
