import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/bloc/labour_cost_form_bloc/labour_cost_form_bloc.dart';
import 'package:construculator/features/estimation/presentation/widgets/calc_method_card.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class LabourCostFormFields extends StatefulWidget {
  final bool fromCostFile;
  final ValueChanged<double>? onTotalChanged;
  final ValueChanged<bool>? onSaveEnabledChanged;

  const LabourCostFormFields({
    super.key,
    required this.fromCostFile,
    this.onTotalChanged,
    this.onSaveEnabledChanged,
  });

  @override
  State<LabourCostFormFields> createState() => _LabourCostFormFieldsState();
}

class _LabourCostFormFieldsState extends State<LabourCostFormFields> {
  LaborCalculationMethodType _calcMethod = LaborCalculationMethodType.perDay;
  final _labourTypeController = TextEditingController();
  final _crewRateController = TextEditingController();
  final _conditionalValueController = TextEditingController();
  final _crewSizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labourTypeController.addListener(_notifySaveEnabled);
    _crewRateController.addListener(_notifyTotal);
    _conditionalValueController.addListener(_notifyTotal);
    _crewSizeController.addListener(_notifyTotal);
  }

  @override
  void didUpdateWidget(covariant LabourCostFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromCostFile != widget.fromCostFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyTotal());
    }
  }

  @override
  void dispose() {
    _labourTypeController.dispose();
    _crewRateController.dispose();
    _conditionalValueController.dispose();
    _crewSizeController.dispose();
    super.dispose();
  }

  void _notifySaveEnabled() {
    final value = _labourTypeController.text;
    widget.onSaveEnabledChanged?.call(value.trim().isNotEmpty);
    context.read<LabourCostFormBloc>().add(LabourCostItemTypeChanged(value));
  }

  // TODO: [CA-353] Move total calculation into BLoC when submission is wired
  void _notifyTotal() {
    if (widget.fromCostFile) {
      widget.onTotalChanged?.call(0);
      return;
    }
    final crewRate = double.tryParse(_crewRateController.text) ?? 0;
    final conditionalValue = double.tryParse(_conditionalValueController.text) ?? 0;
    final crewSize = double.tryParse(_crewSizeController.text) ?? 0;
    widget.onTotalChanged?.call(crewRate * conditionalValue * crewSize);
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
          // TODO: [CA-336] Add assign task section
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
      // TODO: [CA-298] Populate labour type from selected cost file
      CoreTextField(
        key: const Key('labour_type_field'),
        hintText: l10n.labourTypeLabel,
        readOnly: true,
        enabled: false,
        suffix: CoreIconWidget(
          icon: CoreIcons.arrowDropDown,
          color: colorTheme.iconGrayMid,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CalcMethodCard(
        calcMethod: _calcMethod,
        showRateRow: true,
        onMethodChanged: (method) => setState(() => _calcMethod = method),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('conditional_value_field'),
        hintText: _conditionalFieldLabel(context),
        controller: _conditionalValueController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_size_field'),
        hintText: l10n.crewSizeLabel,
        controller: _crewSizeController,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _manuallyFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      BlocConsumer<LabourCostFormBloc, LabourCostFormState>(
        listenWhen: (_, state) => state is LabourCostFormFailure,
        listener: (_, state) {
          if (state is LabourCostFormFailure) {
            _labourTypeController.text = state.labourType;
          }
        },
        builder: (_, state) {
          final error =
              state is LabourCostFormEditing ? state.itemTypeError : null;
          return CoreTextField(
            key: const Key('labour_type_field'),
            hintText: l10n.labourTypeLabel,
            controller: _labourTypeController,
            errorTextList:
                error != null ? [l10n.labourTypeRequiredError] : null,
          );
        },
      ),
      const SizedBox(height: CoreSpacing.space5),
      CalcMethodCard(
        calcMethod: _calcMethod,
        showRateRow: false,
        onMethodChanged: (method) => setState(() => _calcMethod = method),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_rate_field'),
        hintText: l10n.crewRateLabel,
        controller: _crewRateController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        suffix: CoreIconWidget(
          icon: CoreIcons.dollar,
          color: colorTheme.textHeadline,
          size: 24,
        ),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('conditional_value_field'),
        hintText: _conditionalFieldLabel(context),
        controller: _conditionalValueController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_size_field'),
        hintText: l10n.crewSizeLabel,
        controller: _crewSizeController,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  String _conditionalFieldLabel(BuildContext context) => switch (_calcMethod) {
    LaborCalculationMethodType.perDay => context.l10n.noOfDaysLabel,
    LaborCalculationMethodType.perHour => context.l10n.noOfHoursLabel,
    // TODO: [CA-319] Add Per Unit calculation option
    LaborCalculationMethodType.perUnit => context.l10n.noOfDaysLabel,
  };
}
