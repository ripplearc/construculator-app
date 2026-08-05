import 'package:construculator/features/global_search/domain/entities/search_results.dart';
import 'package:construculator/features/global_search/presentation/widgets/estimation_card_widget.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Scrollable list of search results grouped under a "Most relevant" header.
///
/// Renders [EstimationCard] for each estimation in [results]. The
/// [onEstimationTap] and [onEstimationMenuTap] callbacks are forwarded to each
/// card.
class SearchResultsList extends StatelessWidget {
  /// The search results to display.
  final SearchResults results;

  /// Called when an estimation card body is tapped.
  final void Function(CostEstimate) onEstimationTap;

  /// Called when the overflow menu on an estimation card is tapped.
  /// When null, the menu icon remains visible but is not interactive.
  final void Function(CostEstimate)? onEstimationMenuTap;

  final EstimationTileProvider _estimationTileProvider;

  // TODO(CA-652): Add onCalculationTap and onCalculationMenuTap callbacks once CalculationCard is available.
  // https://ripplearc.youtrack.cloud/issue/CA-652

  /// Creates a [SearchResultsList].
  const SearchResultsList({
    super.key,
    required this.results,
    required this.onEstimationTap,
    this.onEstimationMenuTap,
    required this._estimationTileProvider,
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
                provider: _estimationTileProvider,
              );
            },
          ),
        ),
      ],
    );
  }
}
