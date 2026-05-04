import 'package:construculator/features/estimation/presentation/widgets/shared_estimation_tile.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter/widgets.dart';

/// Concrete [EstimationTileProvider] owned by the estimation feature.
///
/// Returns the feature's [SharedEstimationTile], so consumers wired through DI
/// receive the real widget without depending on its source location.
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
}
