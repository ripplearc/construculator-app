import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Persistent failure state for the search results body, shared by the
/// global search and project search pages.
///
/// Rendered when a performed search fails so the failure stays visible after
/// the error toast dismisses; [onRetry] re-runs the failed search.
class SearchLoadFailureWidget extends StatelessWidget {
  /// Called when the retry button is tapped; re-dispatches the failed search.
  final VoidCallback onRetry;

  /// Creates a [SearchLoadFailureWidget].
  const SearchLoadFailureWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CoreIconWidget(
            icon: CoreIcons.search,
            size: CoreIconSize.size32,
            color: context.colorTheme.iconDark,
          ),
          const SizedBox(height: CoreSpacing.space6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space10,
            ),
            child: Text(
              context.l10n.searchFailureBodyMessage,
              key: const Key('searchFailureBodyMessage'),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMediumRegular.copyWith(
                color: context.colorTheme.textHeadline,
              ),
            ),
          ),
          const SizedBox(height: CoreSpacing.space6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space10,
            ),
            child: CoreButton(
              key: const Key('searchFailureRetryButton'),
              label: context.l10n.searchFailureRetryLabel,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
