import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/presentation/widgets/cost_estimation_tile_data.dart';
import 'package:construculator/libraries/estimation/domain/estimation_tile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Public widget API for displaying a cost estimation summary in the
/// estimation feature.
///
/// Resolves the [EstimationTileProvider] through Modular and delegates
/// rendering, so the concrete tile can evolve without touching call sites.
class CostEstimationTile extends StatelessWidget {
  final CostEstimate estimation;
  final VoidCallback onTap;
  final VoidCallback? onMenuTap;
  final EstimationTileProvider? _provider;

  const CostEstimationTile({
    super.key,
    required this.estimation,
    required this.onTap,
    this.onMenuTap,
    EstimationTileProvider? provider,
  }) : _provider = provider;

  @override
  Widget build(BuildContext context) {
    final provider = _provider ?? Modular.get<EstimationTileProvider>();
    return provider.buildEstimationTile(
      data: CostEstimationTileData(estimation),
      onTap: onTap,
      onMenuTap: onMenuTap,
    );
  }
}
