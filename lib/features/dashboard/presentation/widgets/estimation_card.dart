import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _kEstimationCardMicroSpacing = CoreSpacing.space1 / 2;
const double _kEstimationCardInfoIconSize =
    CoreSpacing.space4 - _kEstimationCardMicroSpacing;

/// A card widget that displays a summary of a single [CostEstimate],
/// including its name and last-updated date and time.
class EstimationCard extends StatelessWidget {
  /// The estimation data displayed by this card.
  final CostEstimate estimation;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  const EstimationCard({
    super.key,
    required this.estimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: CoreSpacing.space40,
        margin: const EdgeInsets.only(right: CoreSpacing.space3),
        padding: const EdgeInsets.all(CoreSpacing.space4),
        decoration: BoxDecoration(
          color: colors.pageBackground,
          borderRadius: BorderRadius.circular(CoreSpacing.space3),
          border: Border.all(color: colors.lineLight),
          boxShadow: CoreShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    estimation.estimateName,
                    style: typography.bodyMediumSemiBold.copyWith(
                      color: colors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: CoreSpacing.space3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: _kEstimationCardInfoIconSize,
                  color: colors.iconGrayMid,
                ),
                const SizedBox(width: CoreSpacing.space2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormatter.format(estimation.updatedAt),
                        style: typography.bodySmallRegular.copyWith(
                          color: colors.textBody,
                        ),
                      ),
                      const SizedBox(height: _kEstimationCardMicroSpacing),
                      Text(
                        timeFormatter
                            .format(estimation.updatedAt)
                            .toLowerCase(),
                        style: typography.bodySmallRegular.copyWith(
                          color: colors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
