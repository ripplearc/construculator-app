import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A single row in the search suggestions list.
///
/// Wraps [CoreSearchRowItem.suggestion] and forwards [query] so the package
/// renders the matching prefix in bold. Supplies a localized trailing-icon
/// semantic label via
/// [AppLocalizations.globalSearchSuggestionFillSemanticLabel].
class GlobalSearchSuggestionItem extends StatelessWidget {
  /// The suggested search term to display.
  final String term;

  /// The current search input value; the matching prefix is rendered bold.
  final String query;

  /// Called when the user taps the row body to run the suggested search.
  final VoidCallback onTap;

  /// Called when the user taps the trailing ↖ icon to fill the search field
  /// with [term] without running a search.
  final VoidCallback onTrailingTap;

  /// Creates a [GlobalSearchSuggestionItem].
  const GlobalSearchSuggestionItem({
    super.key,
    required this.term,
    required this.query,
    required this.onTap,
    required this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoreSearchRowItem.suggestion(
      text: term,
      query: query,
      onTap: onTap,
      onTrailingTap: onTrailingTap,
      trailingSemanticLabel:
          context.l10n.globalSearchSuggestionFillSemanticLabel(term),
    );
  }
}
