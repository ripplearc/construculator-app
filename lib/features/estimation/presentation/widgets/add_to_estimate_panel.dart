import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Why the submit button is disabled: the note shown in place of the totals
/// and the button's own label.
class AddToEstimateBlock {
  /// The text shown on the card in place of the totals.
  final String note;

  /// The disabled button's label. The panel never reads it; the footer in
  /// the add-to-estimate button PR (#706) shows it on the button.
  final String buttonLabel;

  const AddToEstimateBlock({required this.note, required this.buttonLabel});
}

/// The "Adds to this estimate" summary card: the line total, an optional
/// delivery row, and the estimate's total before and after.
class AddToEstimatePanel extends StatelessWidget {
  /// This line's total, including the delivery fee.
  final double lineTotal;

  /// The delivery fee included in [lineTotal]. The delivery row is hidden
  /// when it is null or zero.
  final double? deliveryFee;

  /// The name of the estimate the line is added to.
  final String estimateName;

  /// The estimate's total before this line is added.
  final double estimateTotal;

  /// Why the line cannot be totalled, or null when it can.
  final AddToEstimateBlock? block;

  const AddToEstimatePanel({
    super.key,
    required this.lineTotal,
    required this.deliveryFee,
    required this.estimateName,
    required this.estimateTotal,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = DisplayFormatter.currency;
    final block = this.block;
    final fee = deliveryFee;
    if (block != null) {
      return CoreEstimateSummaryCard.empty(
        title: l10n.addsToEstimateLabel,
        note: block.note,
      );
    }
    final hasDeliveryFee = fee != null && fee > 0;
    final newTotal = money.format(estimateTotal + lineTotal);
    return Semantics(
      excludeSemantics: true,
      label: [
        l10n.addsToEstimateLabel,
        money.format(lineTotal),
        if (hasDeliveryFee)
          '${l10n.addsToEstimateIncludesDelivery} +${money.format(fee)}',
        l10n.addsToEstimateTotalSemantics(
          estimateName,
          money.format(estimateTotal),
          newTotal,
        ),
      ].join('\n'),
      child: CoreEstimateSummaryCard(
        title: l10n.addsToEstimateLabel,
        lineTotal: money.format(lineTotal),
        extraCharge: hasDeliveryFee
            ? CoreEstimateSummaryCharge(
                label: l10n.addsToEstimateIncludesDelivery,
                amount: '+${money.format(fee)}',
              )
            : null,
        estimateName: estimateName,
        totalBeforeSuffix: l10n.addsToEstimateTotalBeforeSuffix(
          money.format(estimateTotal),
        ),
        totalAfter: newTotal,
      ),
    );
  }
}
