import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// The weight of a volume in every stored material, read through the
/// trade-stores repository (UX Design Doc Section 9, "Weight"; requirement
/// R11): one [MaterialWeight] per stored density, in the user's order —
/// the first the material the strip proposes, the rest the ones that answer
/// the same volume behind it — re-emitted whenever the densities change,
/// so a material added from the detail panel, or a density edited there or
/// through the Density pill and written back (R8), shows up in the next
/// emission without a recount being asked for.
///
/// The engine weighs over a [NamedDensity]; this is the one place a stored
/// density becomes one, which keeps the engine free of the feature's
/// entities. The stream is the repository's own watch, so it ends when the
/// repository is disposed.
class WatchMaterialWeightsUseCase {
  final TradeStoresRepository _repository;
  final Trades _trades;

  /// Creates the use case over the repository that holds the densities.
  WatchMaterialWeightsUseCase({
    required this._repository,
    this._trades = const Trades(),
  });

  /// The weight of [volume] in each stored material, written in the tons
  /// of [system], as the store is now and after every change.
  Stream<List<MaterialWeight>> call({
    required Volume volume,
    required MeasurementSystem system,
  }) => _repository.watchDensities().map(
    (densities) => _trades.weightsFor(
      volume,
      densities.map(_densityOf).toList(),
      system: system,
    ),
  );

  NamedDensity _densityOf(StoredDensity density) => NamedDensity(
    name: density.name,
    poundsPerCubicYard: density.poundsPerCubicYard,
  );
}
