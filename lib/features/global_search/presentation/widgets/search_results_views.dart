import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// How close to the list's end (in logical pixels) the user must scroll
// before the next results page is requested.
const double _kLoadMoreExtentThreshold = 200.0;

// Size of the load-more spinner. Smaller than CoreLoadingIndicator's default,
// which is sized for a full-page loading surface rather than a list footer.
const double _kLoadMoreIndicatorSize = CoreSpacing.space12;

const double _kEndOfResultsDividerHeight = 1.0;

/// Scrollable list of search results grouped under a "Most relevant" header.
///
/// Renders [EstimationCard] for each estimation in [results]. The
/// [onEstimationTap] and [onEstimationMenuTap] callbacks are forwarded to each
/// card.
///
/// Supports infinite scroll: when the list is scrolled within
/// [_kLoadMoreExtentThreshold] of its end and [hasMore] is true, [onLoadMore]
/// is invoked. While [isLoadingMore] is true a loading footer renders; when
/// [loadMoreFailed] is true a failure footer with a retry affordance renders
/// instead and scrolling no longer requests pages until [onRetryLoadMore]
/// succeeds. Once [hasMore] is false and the list is not empty, an
/// end-of-results footer closes the list off.
class SearchResultsList extends StatelessWidget {
  /// The search results to display.
  final SearchResults results;

  /// Called when an estimation card body is tapped.
  final void Function(CostEstimate) onEstimationTap;

  /// Called when the overflow menu on an estimation card is tapped.
  /// When null, the menu icon remains visible but is not interactive.
  final void Function(CostEstimate)? onEstimationMenuTap;

  /// Whether more results may exist beyond the loaded pages. When false,
  /// scrolling never invokes [onLoadMore].
  final bool hasMore;

  /// Whether a next-page fetch is in flight; renders the loading footer.
  final bool isLoadingMore;

  /// Whether the last next-page fetch failed; renders the retry footer.
  final bool loadMoreFailed;

  /// Called when the user scrolls near the end of the list and more results
  /// may exist. When null, infinite scroll is disabled.
  final VoidCallback? onLoadMore;

  /// Called when the retry button on the failure footer is tapped.
  final VoidCallback? onRetryLoadMore;

  final EstimationTileProvider _estimationTileProvider;

  // TODO(CA-652): Add onCalculationTap and onCalculationMenuTap callbacks once CalculationCard is available.
  // https://ripplearc.youtrack.cloud/issue/CA-652

  /// Creates a [SearchResultsList].
  const SearchResultsList({
    super.key,
    required this.results,
    required this.onEstimationTap,
    this.onEstimationMenuTap,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.onLoadMore,
    this.onRetryLoadMore,
    required this._estimationTileProvider,
  });

  bool _onScrollNotification(ScrollNotification notification) {
    // Only this list's own scroll position may request a page. A nested
    // scrollable (e.g. a future horizontal chip strip inside a row) bubbles
    // its notifications up here too, and its extentAfter says nothing about
    // how close this list is to its end.
    if (notification.depth != 0) return false;
    final loadMore = onLoadMore;
    // A failed page fetch must not silently re-trigger on scroll; only the
    // retry affordance may re-request it.
    if (loadMore == null || !hasMore || isLoadingMore || loadMoreFailed) {
      return false;
    }
    if (notification.metrics.extentAfter <= _kLoadMoreExtentThreshold) {
      loadMore();
    }
    return false;
  }

  // The one caption style every footer shares; centralized so the three
  // captions cannot drift apart the way the failure footer's colour once did.
  Text _buildFooterCaption(
    BuildContext context,
    String text, {
    required Key key,
  }) {
    return Text(
      text,
      key: key,
      textAlign: TextAlign.center,
      style: context.textTheme.bodyMediumRegular.copyWith(
        color: context.colorTheme.textBody,
      ),
    );
  }

  Widget _buildLoadingFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space4),
      child: Column(
        children: [
          // The indicator carries its own generic "Loading" semantics label;
          // the caption below says the same thing more precisely, so only
          // one of the two should reach a screen reader.
          const ExcludeSemantics(
            child: CoreLoadingIndicator(
              key: Key('searchResultsLoadMoreIndicator'),
              size: _kLoadMoreIndicatorSize,
            ),
          ),
          const SizedBox(height: CoreSpacing.space2),
          _buildFooterCaption(
            context,
            context.l10n.searchResultsLoadMoreLoading,
            key: const Key('searchResultsLoadMoreLoadingMessage'),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfResultsFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space6),
      child: Column(
        children: [
          Divider(
            key: const Key('searchResultsEndOfResultsDivider'),
            height: _kEndOfResultsDividerHeight,
            thickness: _kEndOfResultsDividerHeight,
            color: context.colorTheme.lineLight,
          ),
          const SizedBox(height: CoreSpacing.space6),
          _buildFooterCaption(
            context,
            context.l10n.searchResultsEndOfResults,
            key: const Key('searchResultsEndOfResultsMessage'),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CoreSpacing.space4),
      child: Column(
        children: [
          _buildFooterCaption(
            context,
            context.l10n.searchResultsLoadMoreFailed,
            key: const Key('searchResultsLoadMoreFailedMessage'),
          ),
          const SizedBox(height: CoreSpacing.space4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CoreSpacing.space10,
            ),
            child: CoreButton(
              key: const Key('searchResultsLoadMoreRetryButton'),
              label: context.l10n.searchFailureRetryLabel,
              onPressed: onRetryLoadMore,
            ),
          ),
        ],
      ),
    );
  }

  // The footer that closes the list off, or null when the list is open-ended.
  // Resolved to a single widget so every footer renders under one shared
  // gutter — the same space4 inset the cards above use.
  Widget? _buildFooter(BuildContext context) {
    if (isLoadingMore) return _buildLoadingFooter(context);
    if (loadMoreFailed) return _buildFailureFooter(context);
    // An empty list gets SearchResultsEmptyView instead of this widget,
    // so a row is always present when the footer closes the list off.
    // TODO(CA-979): hasMore is estimation-scoped; widen this guard to cover
    // project rows once per-domain offsets land.
    // https://ripplearc.youtrack.cloud/issue/CA-979
    if (!hasMore && results.estimations.isNotEmpty) {
      return _buildEndOfResultsFooter(context);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.textTheme;
    final appColors = context.colorTheme;
    final menuTap = onEstimationMenuTap;
    final footer = _buildFooter(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: CustomScrollView(
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
                  provider: _estimationTileProvider,
                );
              },
            ),
          ),
          if (footer != null)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: CoreSpacing.space4,
              ),
              sliver: SliverToBoxAdapter(child: footer),
            ),
        ],
      ),
    );
  }
}
