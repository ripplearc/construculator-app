import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/formatting/formatting_helper.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class CostEstimationTile extends StatelessWidget {
  final CostEstimate estimation;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  const CostEstimationTile({
    super.key,
    required this.estimation,
    this.onTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    return Container(
      margin: EdgeInsets.symmetric(vertical: CoreSpacing.space3),
      decoration: BoxDecoration(
        color: appColors?.pageBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: CoreShadows.small,
      ),
      padding: const EdgeInsets.all(CoreSpacing.space4),
      child: GestureDetector(
        key: const Key('tileGestureDetector'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopRow(context),
            const SizedBox(height: CoreSpacing.space3),
            _buildBottomRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final typography = Theme.of(context).coreTypography;
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('moneyIcon'),
          icon: CoreIcons.cost,
          color: appColors?.iconGrayMid,
          size: 24,
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: Text(
            estimation.estimateName,
            style: typography.bodyLargeMedium.copyWith(
              color: appColors?.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onMenuTap,
          child: CoreIconWidget(
            key: const Key('menuIcon'),
            icon: CoreIcons.moreVert,
            color: appColors?.iconDark,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final createdAt = estimation.createdAt;

    final appColors = Theme.of(context).extension<AppColorsExtension>();
    final typography = Theme.of(context).coreTypography;

    return Row(
      children: [
        CoreIconWidget(
          key: const Key('calendarIcon'),
          icon: CoreIcons.calendar,
          color: appColors?.iconGrayMid,
          size: 14,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          FormattingHelper.formatDate(createdAt),
          style: typography.bodySmallRegular,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: appColors?.lineDarkOutline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          FormattingHelper.formatTime(createdAt),
          style: typography.bodySmallRegular,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Expanded(
          child: Text(
            textAlign: TextAlign.right,
            FormattingHelper.formatCurrency(estimation.totalCost),
            style: typography.bodyLargeSemiBold.copyWith(
              color: appColors?.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
