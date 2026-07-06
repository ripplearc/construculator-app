import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favorite_estimation_entity.dart';
import 'package:construculator/features/dashboard/domain/entities/favourite_filter_type.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_calculation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favorite_estimation_card.dart';
import 'package:construculator/features/dashboard/presentation/widgets/favourite_sort_bottom_sheet.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the Favourites section on the dashboard. Shows a header row with
/// a "View all" button and, when [calculations] and [estimations] are both
/// empty, renders a centred empty-state message; otherwise renders a vertical
/// list of [FavoriteCalculationCard]s followed by [FavoriteEstimationCard]s.
class FavoritesSection extends StatelessWidget {
  /// The list of favourited calculations to display.
  final List<FavoriteCalculation> calculations;

  /// The list of favourited estimations to display.
  final List<FavoriteEstimation> estimations;

  /// Called when the "View all" text is tapped.
  final VoidCallback onViewAll;

  /// Called with the [FavoriteCalculation.id] when a calculation card is tapped.
  final void Function(String id) onCalculationTap;

  /// Called with the [FavoriteEstimation.id] when an estimation card is tapped.
  final void Function(String id) onEstimationTap;

  /// The currently active filter; controls which items are visible.
  final FavouriteFilterType selectedFilter;

  /// Called with the chosen [FavouriteFilterType] when the user picks an option
  /// from the sort bottom sheet.
  final void Function(FavouriteFilterType) onFilterChanged;

  const FavoritesSection({
    super.key,
    required this.calculations,
    required this.estimations,
    required this.onViewAll,
    required this.onCalculationTap,
    required this.onEstimationTap,
    this.selectedFilter = FavouriteFilterType.all,
    required this.onFilterChanged,
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Semantics(
                  label: context.l10n.sortFavouriteSemanticLabel,
                  button: true,
                  child: GestureDetector(
                    onTap: () => FavouriteSortBottomSheet.show(
                      context,
                      selectedFilter: selectedFilter,
                      onFilterSelected: onFilterChanged,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(CoreSpacing.space2),
                      child: CoreIconWidget(
                        icon: CoreIcons.arrowDropDown,
                        size: CoreIconSize.size20,
                        color: colors.textLink,
                      ),
                    ),
                  ),
                ),
              ],
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
