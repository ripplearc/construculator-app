import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Why the submit button is disabled: the note shown in place of the totals
/// and the button's own label.
class AddToEstimateBlock {
  final String note;
  final String buttonLabel;

  const AddToEstimateBlock({required this.note, required this.buttonLabel});
}

/// The "Adds to this estimate" summary card: the line total, an optional
/// delivery row, and the estimate's total before and after.
class AddToEstimatePanel extends StatelessWidget {
  final double lineTotal;
  final double? deliveryFee;
  final String estimateName;
  final double estimateTotal;
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
    final colorTheme = context.colorTheme;
    final textTheme = context.textTheme;
    final money = DisplayFormatter.currency;
    final block = this.block;
    final fee = deliveryFee;
    final smallBody = textTheme.bodySmallRegular.copyWith(
      color: colorTheme.textBody,
    );
    final beforeStyle = smallBody.copyWith(color: colorTheme.textDisable);
    return MergeSemantics(
      child: Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorTheme.backgroundBlueLight,
            // TODO: [CA-1255] use a CoreUI estimate summary card instead of these hardcoded numbers. https://ripplearc.youtrack.cloud/issue/CA-1255
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.addsToEstimateLabel, style: smallBody),
                const SizedBox(height: 1),
                SizedBox(
                  height: 40,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: block == null
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money.format(lineTotal),
                              style: textTheme.headlineLargeSemiBold.copyWith(
                                color: colorTheme.textHeadline,
                                letterSpacing: -0.32,
                              ),
                            ),
                          )
                        : Text(
                            '—',
                            style: textTheme.titleLargeSemiBold.copyWith(
                              color: colorTheme.textDisable,
                            ),
                          ),
                  ),
                ),
                if (block == null && fee != null && fee > 0) ...[
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.addsToEstimateIncludesDelivery,
                          style: smallBody,
                        ),
                        Text('+${money.format(fee)}', style: smallBody),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 1),
                Padding(
                  padding: const EdgeInsets.only(top: 9, bottom: 7),
                  child: Container(
                    height: 1,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? colorTheme.lineLight
                        // ignore: avoid_static_colors
                        : const Color(0xFFC7ECFA),
                  ),
                ),
                const SizedBox(height: 1),
                if (block != null)
                  Text(block.note, style: smallBody)
                else
                  SizedBox(
                    height: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) => Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    estimateName,
                                    style: beforeStyle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.7,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      l10n.addsToEstimateTotalBeforeSuffix(
                                        money.format(estimateTotal),
                                      ),
                                      style: beforeStyle,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: CoreSpacing.space2),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              money.format(estimateTotal + lineTotal),
                              style: textTheme.bodyLargeSemiBold.copyWith(
                                color: colorTheme.textHeadline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
