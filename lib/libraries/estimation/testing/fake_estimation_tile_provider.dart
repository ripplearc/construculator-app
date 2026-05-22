import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile_data.dart';
import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter/widgets.dart';

/// A test double for [EstimationTileProvider] that renders the real
/// [SharedEstimationTile], so screenshot and widget tests see the actual UI
/// without importing the concrete [EstimationTileProviderImpl].
class FakeEstimationTileProvider implements EstimationTileProvider {
  const FakeEstimationTileProvider();

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
