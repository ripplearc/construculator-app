import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class LabourCostFormFields extends StatefulWidget {
  final bool fromCostFile;

  const LabourCostFormFields({super.key, required this.fromCostFile});

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
  void dispose() {
    _labourTypeController.dispose();
    _crewRateController.dispose();
    _conditionalValueController.dispose();
    _crewSizeController.dispose();
    super.dispose();
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
      // TODO: [CA-298] Pass showRateRow: true once a cost file is selected and rate is wired from CostFileDataSource
      _buildCalcMethodCard(context, showRateRow: false),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('conditional_value_field'),
        label: _conditionalFieldLabel(context),
        controller: _conditionalValueController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_size_field'),
        label: l10n.crewSizeLabel,
        controller: _crewSizeController,
        keyboardType: TextInputType.number,
      ),
    ];
  }

  List<Widget> _manuallyFields(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    return [
      CoreTextField(
        key: const Key('labour_type_field'),
        hintText: l10n.labourTypeLabel,
        controller: _labourTypeController,
      ),
      const SizedBox(height: CoreSpacing.space5),
      _buildCalcMethodCard(context, showRateRow: false),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_rate_field'),
        label: l10n.crewRateLabel,
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
        label: _conditionalFieldLabel(context),
        controller: _conditionalValueController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      const SizedBox(height: CoreSpacing.space5),
      CoreTextField(
        key: const Key('crew_size_field'),
        label: l10n.crewSizeLabel,
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

  Widget _buildCalcMethodCard(BuildContext context, {required bool showRateRow}) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Container(
      key: const Key('calc_method_card'),
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.circular(8),
        boxShadow: CoreShadows.small,
      ),
      padding: const EdgeInsets.all(CoreSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.calcMethodTitle,
            style: textTheme.bodyMediumMedium.copyWith(
              color: colorTheme.textHeadline,
            ),
          ),
          const SizedBox(height: CoreSpacing.space3),
          Wrap(
            spacing: CoreSpacing.space8,
            runSpacing: CoreSpacing.space2,
            children: [
              _CalcMethodRadioOption(
                key: const Key('per_day_option'),
                label: l10n.perDayOption,
                isSelected: _calcMethod == LaborCalculationMethodType.perDay,
                onTap: () => setState(
                  () => _calcMethod = LaborCalculationMethodType.perDay,
                ),
              ),
              _CalcMethodRadioOption(
                key: const Key('per_hours_option'),
                label: l10n.perHoursOption,
                isSelected: _calcMethod == LaborCalculationMethodType.perHour,
                onTap: () => setState(
                  () => _calcMethod = LaborCalculationMethodType.perHour,
                ),
              ),
              // TODO: [CA-319] Add Per Unit calculation option
            ],
          ),
          if (showRateRow) ...[
            const SizedBox(height: CoreSpacing.space3),
            // TODO: [CA-298] Wire rate label to CostFileDataSource
            Row(
              key: const Key('rate_row'),
              children: [
                Text(
                  'Rate/Day:',
                  style: textTheme.bodySmallRegular.copyWith(
                    color: colorTheme.textBody,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space1),
                Text(
                  '\$0',
                  style: textTheme.bodySmallMedium.copyWith(
                    color: colorTheme.textHeadline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CalcMethodRadioOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalcMethodRadioOption({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreIconWidget(
                icon: isSelected ? CoreIcons.radioChecked : CoreIcons.radio,
                color: isSelected ? colorTheme.iconDark : colorTheme.iconGrayMid,
                size: 24,
              ),
              const SizedBox(width: CoreSpacing.space2),
              Text(
                label,
                style: textTheme.bodyMediumRegular.copyWith(
                  color: isSelected
                      ? colorTheme.textHeadline
                      : colorTheme.textBody,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
