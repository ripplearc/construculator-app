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
///
/// Over a line already on the estimate the card is titled "Changes this
/// estimate" and shows the difference. Before any change its title reads
/// "No change yet" and the difference is +\$0.00.
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

  /// How much saving moves the estimate total, in dollars, when the panel is
  /// above a line that is already on the estimate; `null` when a new line is
  /// being added. The panel then shows that difference and the new total,
  /// and leaves out the delivery charge row, which is already inside the
  /// difference.
  final double? changeInEstimateTotal;

  const AddToEstimatePanel({
    super.key,
    required this.lineTotal,
    required this.deliveryFee,
    required this.estimateName,
    required this.estimateTotal,
    required this.block,
    this.changeInEstimateTotal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = DisplayFormatter.currency;
    final block = this.block;
    final fee = deliveryFee;
    final change = changeInEstimateTotal;
    final title = switch (change) {
      null => l10n.addsToEstimateLabel,
      0 => l10n.noChangeYetNote,
      _ => l10n.changesThisEstimateLabel,
    };
    if (block != null) {
      return CoreEstimateSummaryCard.empty(
        title: change == null
            ? l10n.addsToEstimateLabel
            : l10n.changesThisEstimateLabel,
        note: block.note,
      );
    }
    final shownAmount = change == null
        ? money.format(lineTotal)
        : '${change < 0 ? '-' : '+'}${money.format(change.abs())}';
    final hasDeliveryFee = change == null && fee != null && fee > 0;
    final newTotal = money.format(estimateTotal + (change ?? lineTotal));
    return Semantics(
      excludeSemantics: true,
      label: [
        title,
        shownAmount,
        if (hasDeliveryFee)
          '${l10n.addsToEstimateIncludesDelivery} +${money.format(fee)}',
        l10n.addsToEstimateTotalSemantics(
          estimateName,
          money.format(estimateTotal),
          newTotal,
        ),
      ].join('\n'),
      // TODO: [CA-1379] the charge row is 6 dp taller than the storyboard until CoreUI drops its 24 dp minimum height
      // https://ripplearc.youtrack.cloud/issue/CA-1379
      child: CoreEstimateSummaryCard(
        title: title,
        lineTotal: shownAmount,
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
