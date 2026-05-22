import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile_data.dart';
import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter/widgets.dart';

/// Concrete [EstimationTileProvider] owned by the estimation feature.
///
/// Returns the feature's [SharedEstimationTile], so consumers wired through DI
/// receive the real widget without depending on its source location.
class EstimationTileProviderImpl implements EstimationTileProvider {
  const EstimationTileProviderImpl();

  /// Builds the estimation feature's concrete [SharedEstimationTile].
  @override
  Widget buildEstimationTile({
    required EstimationTileData data,
    required VoidCallback onTap,
    VoidCallback? onMenuTap,
  }) {
    return SharedEstimationTile(
      data: data,
      onTap: onTap,
      onMenuTap: onMenuTap,
    );
  }

  /// Maps [estimate] to [CostEstimationTileData] internally and delegates to
  /// [buildEstimationTile], so callers outside this feature need no feature-layer imports.
  @override
  Widget buildFromEstimate({
    required CostEstimate estimate,
    required VoidCallback onTap,
    VoidCallback? onMenuTap,
  }) {
    return buildEstimationTile(
      data: CostEstimationTileData(estimate),
      onTap: onTap,
      onMenuTap: onMenuTap,
    );
  }
}
