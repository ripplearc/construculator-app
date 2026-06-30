import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_calculation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the Favourites section on the dashboard, combining favorited
/// calculations and cost estimations in a vertical list.
class FavoritesSection extends StatelessWidget {
  final List<FavoriteCalculation> calculations;
  final List<FavoriteEstimation> estimations;
  final VoidCallback onViewAll;
  final void Function(String id) onCalculationTap;
  final void Function(String id) onEstimationTap;

  const FavoritesSection({
    super.key,
    required this.calculations,
    required this.estimations,
    required this.onViewAll,
    required this.onCalculationTap,
    required this.onEstimationTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final isEmpty = calculations.isEmpty && estimations.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.favouritesSectionTitle,
              style: typography.titleMediumSemiBold.copyWith(
                color: colors.textDark,
              ),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                context.l10n.viewAllButton,
                style: typography.bodyMediumSemiBold.copyWith(
                  color: colors.textLink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: CoreSpacing.space4),
        if (isEmpty)
          Center(
            child: Text(
              context.l10n.favouritesEmptyState,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.textBody,
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < calculations.length; i++) ...[
                FavoriteCalculationCard(
                  calculation: calculations[i],
                  onTap: () => onCalculationTap(calculations[i].id),
                ),
                if (i < calculations.length - 1 || estimations.isNotEmpty)
                  const SizedBox(height: CoreSpacing.space3),
              ],
              for (int i = 0; i < estimations.length; i++) ...[
                FavoriteEstimationCard(
                  estimation: estimations[i],
                  onTap: () => onEstimationTap(estimations[i].id),
                ),
                if (i < estimations.length - 1)
                  const SizedBox(height: CoreSpacing.space3),
              ],
            ],
          ),
      ],
    );
  }
}
