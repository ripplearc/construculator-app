import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _kProjectListItemBorderWidth = 1;
const double _kProjectListItemSelectedBorderWidth = 2;
const double _kProjectListItemMetaIconSize = CoreSpacing.space4;
const double _kProjectListItemSettingsHitTarget = CoreSpacing.space12;

/// A card widget that displays a summary of a single [Project] within the
/// projects bottom sheet, showing the project name and its last-updated
/// date and time, plus a per-project settings affordance.
///
/// When [isSelected] is true the card is highlighted to indicate it is the
/// currently active project.
class ProjectListItem extends StatelessWidget {
  /// The project data displayed by this item.
  final Project project;

  /// Whether this project is the currently selected one.
  final bool isSelected;

  /// Called when the item body is tapped to select the project.
  final VoidCallback? onTap;

  /// Called when the per-project settings affordance is tapped.
  final VoidCallback? onSettingsTap;

  const ProjectListItem({
    super.key,
    required this.project,
    this.isSelected = false,
    this.onTap,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    final dateFormatter = DateFormat('MMM d, yyyy');
    final timeFormatter = DateFormat('h:mm a');
    final formattedDate = dateFormatter.format(project.updatedAt);
    final formattedTime = timeFormatter.format(project.updatedAt).toLowerCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        key: const Key('project_list_item_card'),
        margin: const EdgeInsets.only(bottom: CoreSpacing.space3),
        padding: const EdgeInsets.all(CoreSpacing.space4),
        decoration: BoxDecoration(
          color: colors.pageBackground,
          borderRadius: BorderRadius.circular(CoreSpacing.space3),
          border: Border.all(
            color: isSelected ? colors.outlineFocus : colors.lineLight,
            width: isSelected
                ? _kProjectListItemSelectedBorderWidth
                : _kProjectListItemBorderWidth,
          ),
          boxShadow: CoreShadows.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    project.projectName,
                    style: typography.titleMediumSemiBold.copyWith(
                      color: colors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space2),
                _buildSettingsButton(context),
              ],
            ),
            const SizedBox(height: CoreSpacing.space2),
            Row(
              children: [
                CoreIconWidget(
                  icon: CoreIcons.calendar,
                  size: _kProjectListItemMetaIconSize,
                  color: colors.iconGrayMid,
                ),
                const SizedBox(width: CoreSpacing.space2),
                Flexible(
                  child: Text(
                    '$formattedDate • $formattedTime',
                    style: typography.bodySmallRegular.copyWith(
                      color: colors.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    final colors = context.colorTheme;
    final hitTarget = SizedBox(
      width: _kProjectListItemSettingsHitTarget,
      height: _kProjectListItemSettingsHitTarget,
      child: GestureDetector(
        onTap: onSettingsTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: CoreIconWidget(
            icon: CoreIcons.settings,
            size: _kProjectListItemMetaIconSize,
            color: colors.iconGrayMid,
          ),
        ),
      ),
    );

    if (onSettingsTap != null) {
      return Semantics(
        button: true,
        label: context.l10n.projectSettingsSemanticLabel,
        child: hitTarget,
      );
    }

    return ExcludeSemantics(child: hitTarget);
  }
}
