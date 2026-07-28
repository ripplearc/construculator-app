import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Persistent in-body failure state, shared by GlobalSearchPage and ProjectSearchPage.
class SearchLoadFailureWidget extends StatelessWidget {
  /// Called when the retry button is tapped; re-dispatches the failed search.
  final VoidCallback onRetry;

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
