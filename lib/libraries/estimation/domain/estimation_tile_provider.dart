import 'package:construculator/libraries/estimation/domain/estimation_tile_data.dart';
import 'package:flutter/widgets.dart';

/// Provides a feature-owned estimation tile widget to any consumer.
///
/// Library consumers depend only on this contract; the concrete widget is
/// stocked by the estimation feature and resolved at runtime through Modular.
abstract class EstimationTileProvider {
  /// Builds and returns the concrete estimation tile widget using the provided [data].
  ///
  /// The [onTap] callback is invoked when the tile body is tapped.
  /// The optional [onMenuTap] callback is invoked when the menu icon is tapped.
  Widget buildEstimationTile({
    required EstimationTileData data,
    required VoidCallback onTap,
    VoidCallback? onMenuTap,
  });
}
