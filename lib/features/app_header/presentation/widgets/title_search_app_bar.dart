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

  @override
  Widget build(BuildContext context) {
    final coreColors = Theme.of(context).coreColors;
    return Container(
      decoration: BoxDecoration(
        color: coreColors.pageBackground,
        boxShadow: CoreShadows.medium,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: CoreSpacing.space4,
        vertical: CoreSpacing.space2,
      ),
      child: AppBar(
        backgroundColor: coreColors.pageBackground,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: Semantics(
          label: context.l10n.projectDropdownSemanticLabel,
          button: true,
          child: InkWell(
            key: const Key('title_search_app_bar_project_selector'),
            onTap: onProjectTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    context.l10n.appTitle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: CoreSpacing.space1),
                CoreIconWidget(
                  icon: CoreIcons.arrowDropDown,
                  color: coreColors.iconGrayMid,
                  size: CoreIconSize.size24,
                ),
              ],
            ),
          ),
        ),
        actions: [
          CoreIconWidget(
            key: const Key('title_search_app_bar_search_button'),
            icon: CoreIcons.search,
            semanticLabel: context.l10n.dashboardSearchSemanticLabel,
            onTap: onSearchTap,
          ),
          const SizedBox(width: CoreSpacing.space4),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
