import 'package:construculator/features/app_header/presentation/widgets/project_selector_title.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Plain app bar with a project-selector title and a search action, shown
/// when no project is selected.
class TitleSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Called when the search icon is tapped.
  final VoidCallback? onSearchTap;

  /// Called when the title is tapped to open the project selector.
  final VoidCallback? onProjectTap;

  /// Creates a [TitleSearchAppBar] with optional [onSearchTap] and
  /// [onProjectTap] callbacks.
  const TitleSearchAppBar({super.key, this.onSearchTap, this.onProjectTap});

  static const double _height = CoreSpacing.space12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: CoreSpacing.space4,
    vertical: CoreSpacing.space2,
  );

  @override
  Widget build(BuildContext context) {
    final coreColors = context.colorTheme;
    return CoreAppBar(
      height: _height,
      padding: _padding,
      centerTitle: true,
      titleSpacing: 0,
      title: ProjectSelectorTitle(
        selectorKey: const Key('title_search_app_bar_project_selector'),
        onProjectTap: onProjectTap,
      ),
      actions: [
        CoreIconWidget(
          key: const Key('title_search_app_bar_search_button'),
          icon: CoreIcons.search,
          size: CoreIconSize.size24,
          padding: const EdgeInsets.all(CoreSpacing.space3),
          color: coreColors.iconDark,
          semanticLabel: context.l10n.dashboardSearchSemanticLabel,
          onTap: onSearchTap,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(_height + _padding.vertical);
}
