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
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CoreShadowColors.shadowGrey8,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          key: const Key('tileGestureDetector'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopRow(context),
                const SizedBox(height: 12),
                _buildBottomRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        CoreIconWidget(
          key: const Key('moneyIcon'),
          icon: CoreIcons.cost,
          color: CoreIconColors.grayMid,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            estimation.estimateName,
            style: CoreTypography.bodyLargeSemiBold(color: CoreTextColors.dark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: onMenuTap,
          child: CoreIconWidget(
            key: const Key('menuIcon'),
            icon: CoreIcons.moreVert,
            color: CoreIconColors.dark,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final createdAt = estimation.createdAt;

    return Row(
      children: [
        CoreIconWidget(
          key: const Key('calendarIcon'),
          icon: CoreIcons.calendar,
          color: CoreIconColors.grayMid,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          FormattingHelper.formatDate(createdAt),
          style: CoreTypography.bodySmallMedium(color: CoreTextColors.body),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: CoreTextColors.disable,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          FormattingHelper.formatTime(createdAt),
          style: CoreTypography.bodySmallMedium(color: CoreTextColors.body),
        ),
        const Spacer(),
        Text(
          FormattingHelper.formatCurrency(estimation.totalCost),
          style: CoreTypography.bodyLargeSemiBold(color: CoreTextColors.dark),
        ),
      ],
    );
  }
}
