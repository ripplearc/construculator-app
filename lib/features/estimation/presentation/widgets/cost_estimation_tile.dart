import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CostEstimationTile extends StatelessWidget {
  final CostEstimate estimation;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;

  // Static formatters to avoid recreating on every build
  static final _dateFormatter = DateFormat('MMM dd, yyyy');
  static final _timeFormatter = DateFormat('h:mm a');
  static final _currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
        // Money icon
        Image.asset(
          'assets/icons/money_icon_gray.png',
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 12),
        // Title
        Expanded(
          child: Text(
            estimation.estimateName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CoreTextColors.dark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Menu button
        GestureDetector(
          onTap: onMenuTap,
          child: Image.asset(
            'assets/icons/vertical_three_dots_dark_green.png',
            width: 20,
            height: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final createdAt = estimation.createdAt;

    return Row(
      children: [
        // Calendar icon
        Image.asset(
          'assets/icons/calendar_icon_gray.png',
          width: 14,
          height: 14,
        ),
        const SizedBox(width: 8),
        // Date
        Text(
          _dateFormatter.format(createdAt),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CoreTextColors.body,
          ),
        ),
        const SizedBox(width: 8),
        // Separator dot
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: CoreTextColors.disable,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Time
        Text(
          _timeFormatter.format(createdAt),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CoreTextColors.body,
          ),
        ),
        const Spacer(),
        // Cost
        Text(
          estimation.totalCost != null 
            ? _currencyFormatter.format(estimation.totalCost)
            : 'N/A',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: CoreTextColors.dark,
          ),
        ),
      ],
    );
  }
}
