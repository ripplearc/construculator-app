import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:construculator/libraries/estimation/presentation/widgets/cost_estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:flutter/widgets.dart';

/// A test double for [EstimationTileProvider] that renders the real
/// [SharedEstimationTile], so screenshot and widget tests see the actual UI
/// without importing the concrete [EstimationTileProviderImpl].
class FakeEstimationTileProvider implements EstimationTileProvider {
  /// Creates a [FakeEstimationTileProvider].
  const FakeEstimationTileProvider();

  /// Builds and returns a [SharedEstimationTile] using the provided [data].
  ///
  /// The [onTap] callback is invoked when the tile body is tapped.
  /// The optional [onMenuTap] callback is invoked when the menu icon is tapped.
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

  /// Builds the tile widget directly from a [CostEstimate].
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
