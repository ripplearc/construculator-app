import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A card displaying a favorited cost estimation with its title, date/time, and total cost.
class FavoriteEstimationCard extends StatelessWidget {
  static final _dateTimeFormatter = DateFormat("MMM d, yyyy · h:mm a");
  static final _costFormatter = NumberFormat.currency(symbol: '\$');

  final FavoriteEstimation estimation;
  final VoidCallback onTap;
  final VoidCallback? onMoreOptions;

  const FavoriteEstimationCard({
    super.key,
    required this.estimation,
    required this.onTap,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final dateTimeText = _dateTimeFormatter.format(estimation.date).toLowerCase();
    final costText = _costFormatter.format(estimation.totalCost);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          CoreSpacing.space4,
          CoreSpacing.space2,
          CoreSpacing.space4,
          CoreSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: colors.pageBackground,
          borderRadius: BorderRadius.circular(CoreSpacing.space1),
          boxShadow: CoreShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CoreIconWidget(
                  icon: CoreIcons.cost,
                  size: CoreIconSize.size24,
                  color: colors.iconGrayMid,
                ),
                const SizedBox(width: CoreSpacing.space2),
                Expanded(
                  child: Text(
                    estimation.title,
                    style: typography.bodyLargeMedium.copyWith(
                      color: colors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                CoreIconWidget(
                  key: const Key('estimation_more_options'),
                  icon: CoreIcons.moreVert,
                  size: CoreIconSize.size24,
                  color: colors.iconGrayMid,
                  semanticLabel: context.l10n.moreOptionsLabel,
                  onTap: onMoreOptions,
                ),
              ],
            ),
            const SizedBox(height: CoreSpacing.space2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CoreIconWidget(
                      icon: CoreIcons.calendar,
                      size: CoreIconSize.size24,
                      color: colors.iconGrayMid,
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Text(
                      dateTimeText,
                      style: typography.bodySmallRegular.copyWith(
                        color: colors.textBody,
                      ),
                    ),
                  ],
                ),
                Text(
                  costText,
                  style: typography.bodyLargeSemiBold.copyWith(
                    color: colors.textDark,
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
