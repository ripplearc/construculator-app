import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/equipment_cost_form_bloc/equipment_cost_form_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Form fields for adding an equipment cost item.
class EquipmentCostFormFields extends StatefulWidget {
  /// When true, renders fields for selecting from a cost file; otherwise renders manual-entry fields.
  final bool fromCostFile;
  final ValueChanged<double>? onTotalChanged;
  final ValueChanged<bool>? onSaveEnabledChanged;

  const EquipmentCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
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

  /// Owns the Day/Job choice-chip selection. Exactly one of these is true at
  /// all times; kept as persistent notifiers (rather than derived fresh from
  /// bloc state on every build) so the chip's own tap-driven toggle can be
  /// corrected deterministically — see [_selectMethod].
  final _daySelected = ValueNotifier<bool>(true);
  final _jobSelected = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _equipmentNameController.addListener(_onEquipmentNameChanged);
    _quantityController.addListener(_notifyTotal);
    _durationController.addListener(_onDurationChanged);
    _dailyRateController.addListener(_onDailyRateChanged);
    _jobAmountController.addListener(_onJobAmountChanged);
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

  /// Tapping a chip re-drives both notifiers to `false`: [CoreChip] toggles
  /// its own `selected` notifier right after this callback returns (unless
  /// it's a smart chip), so the tapped chip's notifier flips back to `true`
  /// on its own, while the untapped sibling — never auto-toggled — is left
  /// `false`. This holds regardless of which chip was active beforehand, so
  /// re-tapping the already-active chip is a no-op and exclusivity always
  /// holds.
  void _selectMethod(
    EquipmentPricingMethod tapped,
    EquipmentPricingMethod current,
  ) {
    _daySelected.value = false;
    _jobSelected.value = false;
    if (tapped != current) {
      context.read<EquipmentCostFormBloc>().add(
        EquipmentMethodSwitchedEvent(tapped),
      );
    }
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
    widget.onTotalChanged?.call(rawTotal.isFinite ? rawTotal : 0.0);
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
              CoreTextField(
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
                  CoreChip(
                    key: const Key('day_method_chip'),
                    label: l10n.equipmentDayMethodLabel,
                    selected: _daySelected,
                    onTap: () =>
                        _selectMethod(EquipmentPricingMethod.day, data.method),
                  ),
                  const SizedBox(width: CoreSpacing.space2),
                  CoreChip(
                    key: const Key('job_method_chip'),
                    label: l10n.equipmentJobMethodLabel,
                    selected: _jobSelected,
                    onTap: () =>
                        _selectMethod(EquipmentPricingMethod.job, data.method),
                  ),
                ],
              ),
              const SizedBox(height: CoreSpacing.space5),
              if (isDay) ...[
                CoreTextField(
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
                CoreTextField(
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
                CoreTextField(
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
            ],
          );
        },
      ),
    ];
  }
}
