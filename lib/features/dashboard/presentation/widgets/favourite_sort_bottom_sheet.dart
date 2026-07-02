import 'package:construculator/features/dashboard/domain/entities/favourite_filter_type.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A bottom sheet that lets the user filter the Favourites section by type.
///
/// Shows three options — All, Cost estimations, Calculations — and marks the
/// currently active [selectedFilter] with a checkmark and a tinted background.
/// Tapping an option invokes [onFilterSelected] and dismisses the sheet.
class FavouriteSortBottomSheet extends StatelessWidget {
  /// The currently active filter.
  final FavouriteFilterType selectedFilter;

  /// Called with the chosen filter when an option row is tapped.
  final void Function(FavouriteFilterType) onFilterSelected;

  const FavouriteSortBottomSheet({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  /// Shows the sort bottom sheet using [CoreQuickSheet].
  static Future<void> show(
    BuildContext context, {
    required FavouriteFilterType selectedFilter,
    required void Function(FavouriteFilterType) onFilterSelected,
  }) {
    return CoreQuickSheet.show<void>(
      context: context,
      child: FavouriteSortBottomSheet(
        selectedFilter: selectedFilter,
        onFilterSelected: onFilterSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space3,
          ),
          child: Text(
            l10n.sortFavouriteTitle,
            style: typography.titleLargeSemiBold.copyWith(
              color: colors.textHeadline,
            ),
          ),
        ),
        const SizedBox(height: CoreSpacing.space4),
        Padding(
          padding: const EdgeInsets.only(
            left: CoreSpacing.space4,
            right: CoreSpacing.space4,
            bottom: CoreSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _OptionRow(
                label: l10n.sortFavouriteAll,
                isSelected: selectedFilter == FavouriteFilterType.all,
                onTap: () {
                  onFilterSelected(FavouriteFilterType.all);
                  Navigator.of(context).pop();
                },
              ),
              _OptionRow(
                label: l10n.sortFavouriteCostEstimations,
                isSelected: selectedFilter == FavouriteFilterType.costEstimations,
                onTap: () {
                  onFilterSelected(FavouriteFilterType.costEstimations);
                  Navigator.of(context).pop();
                },
              ),
              _OptionRow(
                label: l10n.sortFavouriteCalculations,
                isSelected: selectedFilter == FavouriteFilterType.calculations,
                onTap: () {
                  onFilterSelected(FavouriteFilterType.calculations);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  // Pill radius for selected row, matching Figma's 48px cornerRadius on a 48px
  // tall cell. Unselected rows have no background so their 8px radius is moot.
  static const double _selectedRadius = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(CoreSpacing.space3),
        decoration: BoxDecoration(
          color: isSelected ? colors.orientLight : null,
          borderRadius: BorderRadius.circular(
            isSelected ? _selectedRadius : CoreSpacing.space2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.textDark,
              ),
            ),
            if (isSelected)
              CoreIconWidget(
                icon: CoreIcons.checkMark,
                size: CoreIconSize.size24,
                color: colors.statusSuccess,
              ),
          ],
        ),
      ),
    );
  }
}
