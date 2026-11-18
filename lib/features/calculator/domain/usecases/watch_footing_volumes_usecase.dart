import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// The concrete a length of footing takes at each stored cross-section,
/// read through the trade-stores repository (UX Design Doc Section 9,
/// "Concrete footing"; requirement R9): one [FootingVolume] per stored
/// size of the footing store under the unit system in force, in the
/// user's order, re-emitted whenever the store changes — a cross-section
/// added from the detail panel, or the Cross-section pill edited and
/// written back (R8), shows up in the next emission without a recount
/// being asked for.
///
/// The engine measures over a [PieceSize]; this is the one place a stored
/// footing size becomes one, which keeps the engine free of the feature's
/// entities. The stream is the repository's own watch, so it ends when the
/// repository is disposed.
class WatchFootingVolumesUseCase {
  final TradeStoresRepository _repository;
  final Trades _trades;

  /// Creates the use case over the repository that holds the sizes.
  WatchFootingVolumesUseCase({
    required this._repository,
    this._trades = const Trades(),
  });

  /// The concrete of [length] at each cross-section of the footing store
  /// under [system], written in the cubic unit of [system] whatever unit
  /// the length was typed in (Section 6, "A trade result follows the
  /// System of units setting"), as the store is now and after every change.
  Stream<List<FootingVolume>> call({
    required Length length,
    required MeasurementSystem system,
  }) => _repository
      .watchSizes(SizeStore.footing, system)
      .map(
        (sizes) => _trades.footingVolumesFor(
          length,
          sizes.map(_crossSectionOf).toList(),
          system: system,
        ),
      );

  PieceSize _crossSectionOf(StoredSize size) =>
      PieceSize(width: size.width, height: size.height);
}
