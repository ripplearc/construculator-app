import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays a row of stat cards summarising key project metrics.
///
/// Renders two tappable cards side-by-side — one for cost estimations and one
/// for project members. Purely presentational; all data and tap callbacks are
/// passed in by the caller.
class ProjectStatsCards extends StatelessWidget {
  /// The number of cost estimations associated with the project.
  final int estimationCount;

  /// The number of members invited to the project.
  final int memberCount;

  /// Called when the estimations card is tapped; null makes the card non-interactive.
  final VoidCallback? onEstimationsTap;

  /// Called when the members card is tapped; null makes the card non-interactive.
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
            semanticLabel:
                '${context.l10n.numberOfCostEstimations}: $estimationCount',
          ),
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: _StatCard(
            key: const Key('project_stats_members_card'),
            label: context.l10n.peopleInvited,
            count: memberCount,
            onTap: onMembersTap,
            semanticLabel: '${context.l10n.peopleInvited}: $memberCount',
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
  final String semanticLabel;

  const _StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(CoreSpacing.space4),
          decoration: BoxDecoration(
            color: colors.pageBackground,
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
            border: Border.all(color: colors.lineLight),
            boxShadow: CoreShadows.small,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: typography.bodySmallRegular.copyWith(
                        color: colors.textBody,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: CoreSpacing.space1),
                    Text(
                      '$count',
                      style: typography.bodyMediumSemiBold.copyWith(
                        color: colors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              CoreIconWidget(
                icon: CoreIcons.arrowRight,
                color: colors.iconDark,
                size: CoreIconSize.size24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
