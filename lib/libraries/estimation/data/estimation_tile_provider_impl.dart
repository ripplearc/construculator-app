import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/estimation/presentation/widgets/cost_estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:flutter/widgets.dart';

/// Concrete [EstimationTileProvider] that renders [SharedEstimationTile].
///
/// Lives in the estimation library so any feature can bind it through DI
/// without depending on another feature's internals.
class EstimationTileProviderImpl implements EstimationTileProvider {
  const EstimationTileProviderImpl();

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
