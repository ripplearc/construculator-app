import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class ProjectStatsCards extends StatelessWidget {
  final int estimationCount;
  final int memberCount;
  final VoidCallback? onEstimationsTap;
  final VoidCallback? onMembersTap;

  const ProjectStatsCards({
    super.key,
    required this.estimationCount,
    required this.memberCount,
    this.onEstimationsTap,
    this.onMembersTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            key: const Key('project_stats_estimations_card'),
            label: context.l10n.numberOfCostEstimations,
            count: estimationCount,
            onTap: onEstimationsTap,
          ),
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: _StatCard(
            key: const Key('project_stats_members_card'),
            label: context.l10n.peopleInvited,
            count: memberCount,
            onTap: onMembersTap,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback? onTap;

  const _StatCard({
    super.key,
    required this.label,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(CoreSpacing.space4),
        decoration: BoxDecoration(
          color: colors.pageBackground,
          borderRadius: BorderRadius.circular(CoreSpacing.space3),
          border: Border.all(color: colors.lineLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typography.bodySmallRegular.copyWith(
                    color: colors.textBody,
                  ),
                ),
                const SizedBox(height: CoreSpacing.space1),
                Text(
                  '$count',
                  style: typography.bodyMediumSemiBold.copyWith(
                    color: colors.textDark,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: colors.iconGrayMid,
            ),
          ],
        ),
      ),
    );
  }
}
