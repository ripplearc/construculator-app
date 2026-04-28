import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A card widget that displays a cost estimation summary in global search results.
///
/// Renders the estimation name, last-updated date/time, total cost, and an
/// optional owner name. Fires [onTap] for the card body and [onMenuTap] for
/// the trailing overflow menu.
class EstimationCard extends StatelessWidget {
  /// The cost estimation to display.
  final CostEstimate estimation;

  /// Optional name of the estimation owner; omits the owner row when null.
  final String? ownerName;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the trailing menu icon is tapped; hides the icon when null.
  final VoidCallback? onMenuTap;

  const EstimationCard({
    super.key,
    required this.estimation,
    this.ownerName,
    required this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    return Container(
      margin: EdgeInsets.symmetric(vertical: CoreSpacing.space3),
      decoration: BoxDecoration(
        color: appColors.pageBackground,
        borderRadius: BorderRadius.circular(CoreSpacing.space1),
        boxShadow: CoreShadows.small,
      ),
      padding: const EdgeInsets.fromLTRB(
        CoreSpacing.space4,
        CoreSpacing.space2,
        CoreSpacing.space4,
        CoreSpacing.space4,
      ),
      child: Semantics(
        button: true,
        label: estimation.estimateName,
        child: GestureDetector(
          key: const Key('cardGestureDetector'),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTopRow(context),
              const SizedBox(height: CoreSpacing.space3),
              _buildMiddleRow(context),
              if (ownerName case final owner?) ...[
                const SizedBox(height: CoreSpacing.space3),
                _buildOwnerRow(context, owner),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('moneyIcon'),
          icon: CoreIcons.cost,
          color: appColors.iconGrayMid,
          size: CoreIconSize.size24,
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: Text(
            estimation.estimateName,
            style: typography.bodyLargeMedium.copyWith(color: appColors.textDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Semantics(
          label: onMenuTap != null
              ? context.l10n.estimationMenuLabel(estimation.estimateName)
              : null,
          button: onMenuTap != null,
          excludeSemantics: onMenuTap == null,
          child: SizedBox(
            width: CoreSpacing.space12,
            height: CoreSpacing.space12,
            child: GestureDetector(
              onTap: onMenuTap,
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: CoreIconWidget(
                  key: const Key('menuIcon'),
                  icon: CoreIcons.moreVert,
                  color: appColors.iconDark,
                  size: CoreIconSize.size24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiddleRow(BuildContext context) {
    final updatedAt = estimation.updatedAt;
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('calendarIcon'),
          icon: CoreIcons.calendar,
          color: appColors.iconGrayMid,
          size: CoreIconSize.size16,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  DisplayFormatter.formatDate(updatedAt),
                  style: typography.bodySmallRegular,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: CoreSpacing.space2),
              Container(
                width: CoreSpacing.space1,
                height: CoreSpacing.space1,
                decoration: BoxDecoration(
                  color: appColors.lineDarkOutline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: CoreSpacing.space2),
              Flexible(
                child: Text(
                  DisplayFormatter.formatTime(updatedAt),
                  style: typography.bodySmallRegular,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          DisplayFormatter.formatCurrency(estimation.totalCost),
          style: typography.bodyLargeSemiBold.copyWith(color: appColors.textDark),
        ),
      ],
    );
  }

  Widget _buildOwnerRow(BuildContext context, String owner) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('personIcon'),
          icon: CoreIcons.person,
          color: appColors.iconGrayMid,
          size: CoreIconSize.size16,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Text(
            context.l10n.estimationCardOwner(owner),
            style: typography.bodySmallRegular,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
