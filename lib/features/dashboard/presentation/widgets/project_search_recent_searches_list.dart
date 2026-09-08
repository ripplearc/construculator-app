import 'package:construculator/libraries/global_search/presentation/widgets/recent_search_item.dart';
import 'package:flutter/material.dart';

/// A scrollable list of recent project search terms.
///
/// Displays one [RecentSearchItem] per entry in [recentSearches]. All
/// interaction is delegated upward via callbacks — this widget holds no
/// BLoC references.
///
/// [recentSearches] must be non-empty; use [ProjectSearchEmptyRecentWidget]
/// for the empty state. This widget uses a bare [ListView.builder] and must be
/// placed inside a bounded vertical context (e.g. [Expanded] or a fixed-height
/// container) to avoid an unbounded-height layout exception.
class ProjectSearchRecentSearchesList extends StatelessWidget {
  /// The ordered list of recent search terms to display.
  final List<String> recentSearches;

  /// Called when the user taps a row body to run that search.
  final ValueChanged<String> onItemTap;

  /// Called when the user taps the trailing ↗ icon to fill the search field.
  final ValueChanged<String> onTrailingTap;

  /// Called when the user swipes a row to delete the term from history.
  /// Resolves true once the deletion succeeded (completing the dismissal)
  /// and false when it failed (sliding the row back).
  final Future<bool> Function(String term) onItemDismissRequested;

  /// Creates a [ProjectSearchRecentSearchesList].
  const ProjectSearchRecentSearchesList({
    super.key,
    required this.recentSearches,
    required this.onItemTap,
    required this.onTrailingTap,
    required this.onItemDismissRequested,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      recentSearches.isNotEmpty,
      'Use ProjectSearchEmptyRecentWidget for empty state',
    );
    return ListView.builder(
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final term = recentSearches[index];
        return RecentSearchItem(
          key: ValueKey('recent_search_item_$term'),
          term: term,
          onTap: () => onItemTap(term),
          onTrailingTap: () => onTrailingTap(term),
          onDismissRequested: () => onItemDismissRequested(term),
        );
      },
    );
  }
}
