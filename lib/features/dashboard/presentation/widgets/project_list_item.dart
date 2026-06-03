import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _kProjectListItemBorderWidth = 1;
const double _kProjectListItemSelectedBorderWidth = 2;
const double _kProjectListItemMetaIconSize = CoreSpacing.space4;
const double _kProjectListItemSettingsHitTarget = CoreSpacing.space12;

final _dateFormatCache = <String, DateFormat>{};
final _timeFormatCache = <String, DateFormat>{};

DateFormat _dateFormat(String locale) =>
    _dateFormatCache.putIfAbsent(locale, () => DateFormat('MMM d, yyyy', locale));

DateFormat _timeFormat(String locale) =>
    _timeFormatCache.putIfAbsent(locale, () => DateFormat('h:mm a', locale));

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

    final locale = Localizations.localeOf(context).toLanguageTag();
    final formattedDate = _dateFormat(locale).format(project.updatedAt);
    final formattedTime =
        _timeFormat(locale).format(project.updatedAt).toLowerCase();

    final card = Material(
      borderRadius: BorderRadius.circular(CoreSpacing.space3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
        child: Container(
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
                    child: ExcludeSemantics(
                      child: Text(
                        project.projectName,
                        style: typography.titleMediumSemiBold.copyWith(
                          color: colors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: CoreSpacing.space2),
                  _buildSettingsButton(context),
                ],
              ),
              const SizedBox(height: CoreSpacing.space2),
              Row(
                children: [
                  ExcludeSemantics(
                    child: CoreIconWidget(
                      icon: CoreIcons.calendar,
                      size: _kProjectListItemMetaIconSize,
                      color: colors.iconGrayMid,
                    ),
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
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        label: project.projectName,
        child: card,
      );
    }
    return card;
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
