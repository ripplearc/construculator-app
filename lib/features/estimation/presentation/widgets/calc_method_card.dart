import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/calc_method_radio_option.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Card that displays labour calculation method radio options and, optionally,
/// the current cost-file rate. Set [showRateRow] to reveal the rate display.
class CalcMethodCard extends StatelessWidget {
  final LaborCalculationMethodType calcMethod;
  final bool showRateRow;
  final ValueChanged<LaborCalculationMethodType> onMethodChanged;

  const CalcMethodCard({
    super.key,
    required this.calcMethod,
    required this.showRateRow,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    return Container(
      key: const Key('calc_method_card'),
      decoration: BoxDecoration(
        color: colorTheme.pageBackground,
        borderRadius: BorderRadius.circular(CoreSpacing.space2),
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
              CalcMethodRadioOption(
                key: const Key('per_day_option'),
                label: l10n.perDayOption,
                isSelected: calcMethod == LaborCalculationMethodType.perDay,
                onTap: () => onMethodChanged(LaborCalculationMethodType.perDay),
              ),
              CalcMethodRadioOption(
                key: const Key('per_hours_option'),
                label: l10n.perHoursOption,
                isSelected: calcMethod == LaborCalculationMethodType.perHour,
                onTap: () => onMethodChanged(LaborCalculationMethodType.perHour),
              ),
              // TODO: [CA-319] Add Per Unit calculation option
            ],
          ),
          if (showRateRow) ...[
            const SizedBox(height: CoreSpacing.space3),
            // TODO: [CA-298] Wire rate value to CostFileDataSource
            Row(
              key: const Key('rate_row'),
              children: [
                Text(
                  _rateLabel(context),
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

  String _rateLabel(BuildContext context) => switch (calcMethod) {
    LaborCalculationMethodType.perDay => context.l10n.rateDayLabel,
    LaborCalculationMethodType.perHour => context.l10n.rateHourLabel,
    // TODO: [CA-319] Add Per Unit rate label
    LaborCalculationMethodType.perUnit => context.l10n.rateDayLabel,
  };
}
