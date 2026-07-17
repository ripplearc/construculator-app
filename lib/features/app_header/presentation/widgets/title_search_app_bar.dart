import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Plain app bar with the app title and a search action, shown on non-home
/// tabs when no project is selected.
class TitleSearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Called when the search icon is tapped.
  final VoidCallback? onSearchTap;

  /// Creates a [TitleSearchAppBar] with an optional [onSearchTap] callback.
  const TitleSearchAppBar({super.key, this.onSearchTap});

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
        title: Text(context.l10n.appTitle),
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
