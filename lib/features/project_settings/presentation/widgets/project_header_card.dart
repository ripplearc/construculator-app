import 'package:construculator/features/project_settings/presentation/widgets/project_stats_cards.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Tinted header card at the top of the project details screen.
///
/// Shows the project name, description, a "last updated" line, and the
/// [ProjectStatsCards] row. Purely presentational; all data and tap callbacks
/// are supplied by the caller.
class ProjectHeaderCard extends StatelessWidget {
  /// Key for the project name text, used by tests.
  static const Key projectNameKey = Key('project_header_card_name');

  /// Key for the description text, used by tests. Absent when [description] is null.
  static const Key descriptionKey = Key('project_header_card_description');

  /// Key for the last-updated line, used by tests.
  static const Key lastUpdatedKey = Key('project_header_card_last_updated');

  /// The project's display name.
  final String projectName;

  /// The project's optional description; when null or blank the description
  /// text is omitted.
  final String? description;

  /// The timestamp shown on the "last updated" line.
  final DateTime lastUpdatedAt;

  /// The number of cost estimations, forwarded to [ProjectStatsCards].
  final int estimationCount;

  /// The number of invited members, forwarded to [ProjectStatsCards].
  final int memberCount;

  /// Called when the estimations stat card is tapped.
  final VoidCallback? onEstimationsTap;

  /// Called when the members stat card is tapped.
  final VoidCallback? onMembersTap;

  const ProjectHeaderCard({
    super.key,
    required this.projectName,
    required this.lastUpdatedAt,
    required this.estimationCount,
    required this.memberCount,
    this.description,
    this.onEstimationsTap,
    this.onMembersTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      padding: const EdgeInsets.all(CoreSpacing.space4),
      color: colors.backgroundBlueLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projectName,
            key: projectNameKey,
            style: typography.titleMediumSemiBold.copyWith(
              color: colors.textDark,
            ),
          ),
          // Treat blank as absent: the backend may store an empty string
          // rather than NULL, which would otherwise render an empty block.
          if (description case final description?
              when description.trim().isNotEmpty) ...[
            const SizedBox(height: CoreSpacing.space2),
            Text(
              description,
              key: descriptionKey,
              style: typography.bodyMediumRegular.copyWith(
                color: colors.textBody,
              ),
            ),
          ],
          const SizedBox(height: CoreSpacing.space4),
          _LastUpdatedLine(timestamp: lastUpdatedAt),
          const SizedBox(height: CoreSpacing.space4),
          ProjectStatsCards(
            estimationCount: estimationCount,
            memberCount: memberCount,
            onEstimationsTap: onEstimationsTap,
            onMembersTap: onMembersTap,
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedLine extends StatelessWidget {
  final DateTime timestamp;

  const _LastUpdatedLine({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;
    final label = context.l10n.projectLastUpdatedLabel(
      DisplayFormatter.formatDate(timestamp),
    );
    final time = DisplayFormatter.formatTime(timestamp);

    return Semantics(
      label: '$label $time',
      excludeSemantics: true,
      child: Row(
        key: ProjectHeaderCard.lastUpdatedKey,
        children: [
          CoreIconWidget(
            icon: CoreIcons.calendar,
            color: colors.iconDark,
            size: CoreIconSize.size16,
          ),
          const SizedBox(width: CoreSpacing.space2),
          Text(
            label,
            style: typography.bodySmallRegular.copyWith(color: colors.textBody),
          ),
          const SizedBox(width: CoreSpacing.space2),
          _Bullet(color: colors.textBody),
          const SizedBox(width: CoreSpacing.space2),
          Text(
            time,
            style: typography.bodySmallRegular.copyWith(color: colors.textBody),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final Color color;

  const _Bullet({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CoreSpacing.space1,
      height: CoreSpacing.space1,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
