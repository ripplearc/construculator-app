import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A search-result card that displays a [Project] summary.
///
/// Follows the shared tile pattern established by `SharedEstimationTile`
/// (same container decoration and row structure, dates via
/// [DisplayFormatter]) so project and estimation results read as one card
/// family in the results list.
///
/// Accessibility: the card is wrapped in [Semantics] with `button: true`
/// and the project name as the label.
class ProjectCard extends StatelessWidget {
  /// The project this card represents.
  final Project project;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Creates a [ProjectCard].
  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    return Semantics(
      button: true,
      label: project.projectName,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space2),
        child: Material(
          borderRadius: BorderRadius.circular(CoreSpacing.space3),
          child: InkWell(
            key: const Key('projectCardInkWell'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(CoreSpacing.space3),
            child: Ink(
              padding: const EdgeInsets.all(CoreSpacing.space4),
              decoration: BoxDecoration(
                color: appColors.pageBackground,
                borderRadius: BorderRadius.circular(CoreSpacing.space3),
                boxShadow: CoreShadows.small,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTopRow(context),
                  const SizedBox(height: CoreSpacing.space3),
                  _buildDateRow(context),
                ],
              ),
            ),
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
          key: const Key('projectIcon'),
          icon: CoreIcons.home,
          color: appColors.iconGrayMid,
          size: CoreIconSize.size24,
        ),
        const SizedBox(width: CoreSpacing.space3),
        Expanded(
          child: Text(
            project.projectName,
            style: typography.bodyLargeMedium.copyWith(
              color: appColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context) {
    final appColors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      children: [
        CoreIconWidget(
          key: const Key('projectCalendarIcon'),
          icon: CoreIcons.calendar,
          color: appColors.iconGrayMid,
          size: CoreIconSize.size16,
        ),
        const SizedBox(width: CoreSpacing.space2),
        Text(
          DisplayFormatter.formatDate(project.updatedAt),
          style: typography.bodySmallRegular,
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
        Text(
          DisplayFormatter.formatTime(project.updatedAt),
          style: typography.bodySmallRegular,
        ),
      ],
    );
  }
}
