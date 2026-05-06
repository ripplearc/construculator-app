import 'package:construculator/features/global_search/presentation/widgets/global_search_recent_search_item.dart';
import 'package:flutter/material.dart';

/// A scrollable list of recent search terms.
///
/// Displays one [GlobalSearchRecentSearchItem] per entry in [recentSearches].
/// All interaction is delegated upward via callbacks — this widget holds no
/// BLoC references.
///
/// [recentSearches] must be non-empty; use [GlobalSearchEmptyRecentWidget]
/// for the empty state. This widget uses a bare [ListView.builder] and must be
/// placed inside a bounded vertical context (e.g. [Expanded] or a fixed-height
/// container) to avoid an unbounded-height layout exception.
class GlobalSearchRecentSearchesList extends StatelessWidget {
  /// The ordered list of recent search terms to display.
  final List<String> recentSearches;

  /// Called when the user taps a row body to run that search.
  final ValueChanged<String> onItemTap;

  /// Called when the user taps the trailing ↗ icon to fill the search field.
  final ValueChanged<String> onTrailingTap;

  /// Creates a [GlobalSearchRecentSearchesList].
  const GlobalSearchRecentSearchesList({
    super.key,
    required this.recentSearches,
    required this.onItemTap,
    required this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    assert(recentSearches.isNotEmpty, 'Use GlobalSearchEmptyRecentWidget for empty state');
    return ListView.builder(
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final term = recentSearches[index];
        return GlobalSearchRecentSearchItem(
          key: ValueKey('recent_search_item_$term'),
          term: term,
          onTap: () => onItemTap(term),
          onTrailingTap: () => onTrailingTap(term),
        );
      },
    );
  }
}
