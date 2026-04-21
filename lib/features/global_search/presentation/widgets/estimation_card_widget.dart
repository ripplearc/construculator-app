import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/formatting_helper.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class EstimationCard extends StatelessWidget {
  final CostEstimate estimation;
  final String? ownerName;
  final VoidCallback onTap;
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
    final owner = ownerName;
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
              if (owner != null) ...[
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
          size: CoreSpacing.space6,
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
                  size: CoreSpacing.space6,
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
          size: CoreSpacing.space3,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  FormattingHelper.formatDate(updatedAt),
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
                  FormattingHelper.formatTime(updatedAt),
                  style: typography.bodySmallRegular,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          FormattingHelper.formatCurrency(estimation.totalCost),
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
          size: CoreSpacing.space3,
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
