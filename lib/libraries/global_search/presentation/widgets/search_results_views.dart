import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _emptyStateMaxMessageWidth = 320.0;

/// Centered loading indicator shown while a search request is in flight.
///
/// Shared by GlobalSearchPage and ProjectSearchPage, like
/// `SearchLoadFailureWidget`.
class SearchResultsLoadingView extends StatelessWidget {
  /// Creates a [SearchResultsLoadingView].
  const SearchResultsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('searchResultsLoadingView'),
      child: CoreLoadingIndicator(key: Key('loadingIndicator')),
    );
  }
}

/// Empty state shown when a search completes with no matching results.
///
/// Shared by GlobalSearchPage and ProjectSearchPage, like
/// `SearchLoadFailureWidget`.
class SearchResultsEmptyView extends StatelessWidget {
  /// The query that produced no results; shown in the message.
  final String query;

  /// Creates a [SearchResultsEmptyView].
  const SearchResultsEmptyView({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('searchResultsEmptyView'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CoreIconWidget(
            key: const Key('emptySearchIcon'),
            icon: CoreIcons.fileSearch,
            size: CoreIconSize.size32,
            color: context.colorTheme.iconGrayMid,
          ),
          const SizedBox(height: CoreSpacing.space6),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _emptyStateMaxMessageWidth,
            ),
            child: Text(
              context.l10n.searchResultsEmpty(query),
              key: const Key('emptySearchMessage'),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMediumRegular.copyWith(
                color: context.colorTheme.textHeadline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
