import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A card displaying a favorited calculation with its date/time and type tags.
class FavoriteCalculationCard extends StatelessWidget {
  /// The favorited calculation data to display.
  final FavoriteCalculation calculation;

  /// Called when the user taps the card body.
  final VoidCallback onTap;

  /// Called when the user taps the more-options icon. Optional.
  final VoidCallback? onMoreOptions;

  static final _dateTimeFormatter = DateFormat("MMM d, yyyy · h:mm a");
  static final _chipNotSelected = ValueNotifier<bool>(false);

  const FavoriteCalculationCard({
    super.key,
    required this.calculation,
    required this.onTap,
    this.onMoreOptions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final dateTimeText = _dateTimeFormatter
        .format(calculation.date)
        .replaceAll('AM', 'am')
        .replaceAll('PM', 'pm');

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CoreIconWidget(
                      icon: CoreIcons.calculate,
                      size: CoreIconSize.size24,
                      color: colors.iconGrayMid,
                    ),
                    const SizedBox(width: CoreSpacing.space2),
                    Text(
                      dateTimeText,
                      style: typography.bodyLargeMedium.copyWith(
                        color: colors.textDark,
                      ),
                    ),
                  ],
                ),
                CoreIconWidget(
                  key: const Key('calculation_more_options'),
                  icon: CoreIcons.moreVert,
                  size: CoreIconSize.size24,
                  color: colors.iconGrayMid,
                  semanticLabel: context.l10n.moreOptionsLabel,
                  onTap: onMoreOptions,
                ),
              ],
            ),
            const SizedBox(height: CoreSpacing.space2),
            IgnorePointer(
              child: Wrap(
                spacing: CoreSpacing.space2,
                runSpacing: CoreSpacing.space2,
                children: [
                  for (final tag in calculation.tags)
                    CoreChip(
                      label: tag,
                      selected: _chipNotSelected,
                      size: CoreChipSize.small,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
