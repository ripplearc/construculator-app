import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// A single row in the recent searches list.
///
/// Wraps [CoreSearchRowItem.recentSearch] and supplies a localized
/// trailing-icon semantic label via [AppLocalizations.globalSearchRecentSearchFillSemanticLabel].
class GlobalSearchRecentSearchItem extends StatelessWidget {
  /// The search term to display.
  final String term;

  /// Called when the user taps the row body to run the search.
  final VoidCallback onTap;

  /// Called when the user taps the trailing ↗ icon to fill the search field.
  final VoidCallback onTrailingTap;

  /// Creates a [GlobalSearchRecentSearchItem].
  const GlobalSearchRecentSearchItem({
    super.key,
    required this.term,
    required this.onTap,
    required this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoreSearchRowItem.recentSearch(
      text: term,
      onTap: onTap,
      onTrailingTap: onTrailingTap,
      trailingSemanticLabel:
          context.l10n.globalSearchRecentSearchFillSemanticLabel(term),
    );
  }
}
