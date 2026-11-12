import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/cost_line_meta_formatter.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_line_card_frame.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// One cost line on the estimate screen: its name and total on the top row
/// and a meta row under the name, inside a [CostLineCardFrame].
///
/// The whole card is tappable, not a small control inside it. Material, Labor
/// and Equipment lines share this row; only the meta row differs, see
/// [CostLineMetaFormatter].
class CostLineRow extends StatelessWidget {
  /// The line to show.
  final CostItem item;

  /// Whether this is the line that was just added.
  final bool isHighlighted;

  /// Called when the user taps the line.
  final VoidCallback? onTap;

  const CostLineRow({
    super.key,
    required this.item,
    required this.isHighlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final nameStyle = textTheme.titleMediumSemiBold.copyWith(
      color: colorTheme.textHeadline,
    );
    final meta = CostLineMetaFormatter.format(item, context.l10n);
    return CostLineCardFrame(
      key: Key('cost_line_frame_${item.id}'),
      isHighlighted: isHighlighted,
      onTap: onTap,
      child: Column(
        key: Key('cost_line_${item.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Row(
              spacing: CoreSpacing.space3,
              children: [
                Expanded(child: Text(item.itemName, style: nameStyle)),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth / 2,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DisplayFormatter.formatCurrency(item.itemTotalCost),
                      style: nameStyle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (meta != null)
            Padding(
              padding: const EdgeInsets.only(top: CoreSpacing.space1),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: meta.lead,
                      style: textTheme.bodySmallSemiBold.copyWith(
                        color: colorTheme.textDark,
                      ),
                    ),
                    TextSpan(
                      text: meta.tail,
                      style: textTheme.bodySmallRegular.copyWith(
                        color: colorTheme.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
