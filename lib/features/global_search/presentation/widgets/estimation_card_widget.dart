import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter/material.dart';

/// A search-result card that displays a [CostEstimate] summary.
///
/// Delegates rendering to [EstimationTileProvider] so the concrete tile widget
/// can evolve without touching this call site.
class EstimationCard extends StatelessWidget {
  /// The cost estimate this card represents.
  final CostEstimate estimation;

  /// Called when the card body is tapped.
  final VoidCallback onTap;

  /// Called when the overflow menu icon is tapped.
  /// When null, the menu icon remains visible but is not interactive.
  final VoidCallback? onMenuTap;

  final EstimationTileProvider _provider;

  /// Creates an [EstimationCard].
  const EstimationCard({
    super.key,
    required this.estimation,
    required this.onTap,
    this.onMenuTap,
    required EstimationTileProvider provider,
  }) : _provider = provider;

  @override
  Widget build(BuildContext context) {
    return _provider.buildFromEstimate(
      estimate: estimation,
      onTap: onTap,
      onMenuTap: onMenuTap,
    );
  }
}
