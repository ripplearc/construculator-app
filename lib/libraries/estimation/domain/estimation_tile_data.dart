/// Data contract for [SharedEstimationTile].
///
/// Features provide a concrete implementation by mapping their domain entities
/// to this interface, keeping the widget free of any feature-layer imports.
abstract class EstimationTileData {
  /// The display name of the estimation.
  String get estimateName;

  /// The total calculated cost; null renders a placeholder dash.
  double? get totalCost;

  /// The timestamp shown in the date/time row (createdAt or updatedAt —
  /// the concrete implementation decides which to expose).
  DateTime get displayDate;
}
