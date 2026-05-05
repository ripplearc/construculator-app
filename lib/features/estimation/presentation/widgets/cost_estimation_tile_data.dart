import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';

/// Maps [CostEstimate] to [EstimationTileData] for use with [SharedEstimationTile].
class CostEstimationTileData implements EstimationTileData {
  final CostEstimate _estimation;

  /// Creates a [CostEstimationTileData] from a [CostEstimate] entity.
  const CostEstimationTileData(this._estimation);

  @override
  String get estimateName => _estimation.estimateName;

  @override
  double? get totalCost => _estimation.totalCost;

  @override
  DateTime get displayDate => _estimation.createdAt;
}
