import 'package:construculator/features/global_search/presentation/widgets/global_search_suggestion_item.dart';
import 'package:flutter/material.dart';

/// A scrollable list of search suggestions.
///
/// Displays one [GlobalSearchSuggestionItem] per entry in [suggestions]. All
/// interaction is delegated upward via callbacks — this widget holds no BLoC
/// references.
///
/// Must be placed inside a bounded vertical context (e.g. [Expanded] or a
/// fixed-height container) to avoid an unbounded-height layout exception.
class GlobalSearchSuggestionsList extends StatelessWidget {
  /// The ordered list of suggestion terms to display.
  final List<String> suggestions;

  /// The current search input value forwarded to each item so the matching
  /// prefix is rendered bold.
  final String query;

  /// Called when the user taps a row body to run the suggested search.
  final ValueChanged<String> onItemTap;

  /// Called when the user taps the trailing ↖ icon to fill the search field.
  final ValueChanged<String> onTrailingTap;

  /// Creates a [GlobalSearchSuggestionsList].
  const GlobalSearchSuggestionsList({
    super.key,
    required this.suggestions,
    required this.query,
    required this.onItemTap,
    required this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final term = suggestions[index];
        return GlobalSearchSuggestionItem(
          key: ValueKey('suggestion_item_$term'),
          term: term,
          query: query,
          onTap: () => onItemTap(term),
          onTrailingTap: () => onTrailingTap(term),
        );
      },
    );
  }
}
