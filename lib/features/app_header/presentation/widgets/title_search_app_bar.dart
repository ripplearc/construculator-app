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

  @override
  Widget build(BuildContext context) {
    final coreColors = Theme.of(context).coreColors;
    return Container(
      decoration: BoxDecoration(
        color: coreColors.pageBackground,
        boxShadow: CoreShadows.medium,
      ),
      // No vertical padding: the icon needs the full [kToolbarHeight] so its
      // tap target can reach 48x48 (CA-822).
      padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
      child: AppBar(
        backgroundColor: coreColors.pageBackground,
        elevation: 0,
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
