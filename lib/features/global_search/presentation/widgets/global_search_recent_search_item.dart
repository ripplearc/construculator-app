import 'dart:async' show unawaited;
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A single row in the recent searches list.
///
/// Wraps [CoreSearchRowItem.recentSearch] and supplies a localized
/// trailing-icon semantic label via [AppLocalizations.globalSearchRecentSearchFillSemanticLabel].
///
/// The row can be swiped end-to-start to delete the term from history;
/// [Dismissible] exposes the swipe as a semantic scroll action for
/// assistive technologies. The trailing ↗ fill-the-field affordance is
/// unchanged.
class GlobalSearchRecentSearchItem extends StatelessWidget {
  /// The search term to display.
  final String term;

  /// Called when the user taps the row body to run the search.
  final VoidCallback onTap;

  /// Called when the user taps the trailing ↗ icon to fill the search field.
  final VoidCallback onTrailingTap;

  /// Called when the user swipes the row to delete the term from history.
  ///
  /// Wired to [Dismissible.confirmDismiss]: the row completes its dismissal
  /// only when the returned future resolves true (the deletion succeeded
  /// and the term has left the list state), and slides back when it
  /// resolves false — so a failed delete never leaves a dismissed row
  /// mounted in the tree.
  final Future<bool> Function() onDismissRequested;

  /// Creates a [GlobalSearchRecentSearchItem].
  const GlobalSearchRecentSearchItem({
    super.key,
    required this.term,
    required this.onTap,
    required this.onTrailingTap,
    required this.onDismissRequested,
  });

  @override
  Widget build(BuildContext context) {
    final appColors = context.colorTheme;
    return Dismissible(
      key: ValueKey('recent_search_dismissible_$term'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDismissRequested(),
      background: Container(
        color: appColors.backgroundRedMid,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: CoreSpacing.space4),
        child: CoreIconWidget(
          key: Key('recent_search_delete_icon_$term'),
          icon: CoreIcons.delete,
          color: appColors.iconRed,
          size: CoreIconSize.size24,
        ),
      ),
      // The swipe gesture is invisible to assistive technologies, so the
      // deletion is also exposed as a labeled custom action; invoking it
      // runs the same confirm-dismiss flow (the row's data drives removal,
      // so the unawaited outcome is safe to drop here).
      child: Semantics(
        customSemanticsActions: {
          CustomSemanticsAction(
            label: context.l10n.globalSearchRecentSearchDeleteSemanticLabel(
              term,
            ),
          ): () {
            unawaited(onDismissRequested());
          },
        },
        child: CoreSearchRowItem.recentSearch(
          text: term,
          onTap: onTap,
          onTrailingTap: onTrailingTap,
          trailingSemanticLabel: context.l10n
              .globalSearchRecentSearchFillSemanticLabel(term),
        ),
      ),
    );
  }
}
