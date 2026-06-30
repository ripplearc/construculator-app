import 'package:construculator/features/dashboard/domain/entities/favorite_calculation_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A card displaying a favorited calculation with its date/time and type tags.
class FavoriteCalculationCard extends StatefulWidget {
  final FavoriteCalculation calculation;
  final VoidCallback onTap;
  final VoidCallback? onMoreOptions;

  const FavoriteCalculationCard({
    super.key,
    required this.calculation,
    required this.onTap,
    this.onMoreOptions,
  });

  @override
  State<FavoriteCalculationCard> createState() =>
      _FavoriteCalculationCardState();
}

class _FavoriteCalculationCardState extends State<FavoriteCalculationCard> {
  static final _dateTimeFormatter = DateFormat("MMM d, yyyy · h:mm a");

  late List<ValueNotifier<bool>> _tagSelected;

  @override
  void initState() {
    super.initState();
    _tagSelected = List.generate(
      widget.calculation.tags.length,
      (_) => ValueNotifier(false),
    );
  }

  @override
  void didUpdateWidget(FavoriteCalculationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.calculation.tags.length != widget.calculation.tags.length) {
      for (final n in _tagSelected) {
        n.dispose();
      }
      _tagSelected = List.generate(
        widget.calculation.tags.length,
        (_) => ValueNotifier(false),
      );
    }
  }

  @override
  void dispose() {
    for (final n in _tagSelected) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final dateTimeText = _dateTimeFormatter.format(widget.calculation.date).toLowerCase();

    return GestureDetector(
      onTap: widget.onTap,
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
                      icon: CoreIcons.calculator,
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
                  onTap: widget.onMoreOptions,
                ),
              ],
            ),
            const SizedBox(height: CoreSpacing.space2),
            Wrap(
              spacing: CoreSpacing.space2,
              runSpacing: CoreSpacing.space2,
              children: [
                for (var i = 0; i < widget.calculation.tags.length; i++)
                  CoreChip(
                    label: widget.calculation.tags[i],
                    selected: _tagSelected[i],
                    size: CoreChipSize.medium,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
