import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';

/// Maps [CostEstimate] to [EstimationTileData] for use with [SharedEstimationTile].
class CostEstimationTileData implements EstimationTileData {
  final CostEstimate _estimation;

  /// Creates a [CostEstimationTileData] from a [CostEstimate] entity.
  const CostEstimationTileData(this._estimation);

  /// The display name of this estimate.
  @override
  String get estimateName => _estimation.estimateName;

  /// The total computed cost, or null when not yet calculated.
  @override
  double? get totalCost => _estimation.totalCost;

  /// The date shown on the tile — mapped from [CostEstimate.createdAt].
  @override
  DateTime get displayDate => _estimation.createdAt;
}
