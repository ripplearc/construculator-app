import 'package:construculator/features/dashboard/presentation/widgets/project_selection_indicator.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _kHighlightedProjectItemMetaIconSize = CoreSpacing.space4;
const double _kHighlightedProjectItemSettingsHitTarget = CoreSpacing.space12;

final _dateFormatCache = <String, DateFormat>{};
final _timeFormatCache = <String, DateFormat>{};

DateFormat _dateFormat(String locale) =>
    _dateFormatCache.putIfAbsent(locale, () => DateFormat('MMM d, yyyy', locale));

DateFormat _timeFormat(String locale) =>
    _timeFormatCache.putIfAbsent(locale, () => DateFormat('h:mm a', locale));

/// The selected-state variant of a project card, rendered when the user's
/// current working project matches this item.
///
/// Visually identical to the unselected [ProjectListItem] except the border
/// comes from [ProjectSelectionIndicator] (3 px cyan) and the widget exposes
/// [SemanticsFlag.isSelected] so screen readers announce the active project.
class HighlightedProjectItem extends StatelessWidget {
  /// The project data displayed by this item.
  final Project project;

  /// Called when the item body is tapped.
  final VoidCallback? onTap;

  /// Called when the per-project settings affordance is tapped.
  final VoidCallback? onSettingsTap;

  const HighlightedProjectItem({
    super.key,
    required this.project,
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
        child: ProjectSelectionIndicator(
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
                      size: _kHighlightedProjectItemMetaIconSize,
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
        selected: true,
        label: project.projectName,
        child: card,
      );
    }
    return card;
  }

  Widget _buildSettingsButton(BuildContext context) {
    final colors = context.colorTheme;
    final hitTarget = SizedBox(
      width: _kHighlightedProjectItemSettingsHitTarget,
      height: _kHighlightedProjectItemSettingsHitTarget,
      child: GestureDetector(
        onTap: onSettingsTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: CoreIconWidget(
            icon: CoreIcons.settings,
            size: _kHighlightedProjectItemMetaIconSize,
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
