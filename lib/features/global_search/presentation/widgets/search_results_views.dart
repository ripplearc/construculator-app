import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

const double _emptyStateMaxMessageWidth = 320.0;

/// Scrollable list of search results grouped under a "Most relevant" header.
///
/// Renders [EstimationCard] for each estimation in [results]. The
/// [onEstimationTap] and [onEstimationMenuTap] callbacks are forwarded to each
/// card. CalculationCard integration is tracked in TODO(CA-652).
class SearchResultsList extends StatelessWidget {
  /// The search results to display.
  final SearchResults results;

  /// Called when an estimation card body is tapped.
  final void Function(CostEstimate) onEstimationTap;

  /// Called when the overflow menu on an estimation card is tapped.
  /// When null, the menu icon remains visible but is not interactive.
  final void Function(CostEstimate)? onEstimationMenuTap;

  // TODO(CA-652): Add onCalculationTap and onCalculationMenuTap callbacks once CalculationCard is available.
  // https://ripplearc.youtrack.cloud/issue/CA-652

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onEstimationTap,
    this.onEstimationMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final appColors = context.colorTheme;
    final menuTap = onEstimationMenuTap;

    return CustomScrollView(
      key: const Key('searchResultsListView'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          sliver: SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: CoreSpacing.space4,
                bottom: CoreSpacing.space2,
              ),
              child: Text(
                context.l10n.searchResultsMostRelevant,
                key: const Key('mostRelevantHeader'),
                style: typography.bodyLargeSemiBold.copyWith(color: appColors.textDark),
              ),
            ),
          ),
        ),
        // TODO(CA-652): Add a SliverList here that renders one CalculationCard per SearchResults.calculations entry.
        // https://ripplearc.youtrack.cloud/issue/CA-652
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space4),
          sliver: SliverList.builder(
            itemCount: results.estimations.length,
            itemBuilder: (context, index) {
              final estimation = results.estimations[index];
              return EstimationCard(
                key: ValueKey('estimationCard_${estimation.id}'),
                estimation: estimation,
                onTap: () => onEstimationTap(estimation),
                onMenuTap: menuTap != null ? () => menuTap(estimation) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Centered loading indicator shown while a search request is in flight.
class SearchResultsLoadingView extends StatelessWidget {
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
class SearchResultsEmptyView extends StatelessWidget {
  /// The query that produced no results; shown in the message.
  final String query;

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
            constraints: const BoxConstraints(maxWidth: _emptyStateMaxMessageWidth),
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
