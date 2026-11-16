import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// The members along a span at each stored on-centre spacing, read through
/// the trade-stores repository (UX Design Doc Section 9, "Quantity at
/// on-centre spacing"; requirement R9): one [SpacingCount] per stored
/// spacing, in the user's order, re-emitted whenever the spacings change —
/// a spacing added from the detail panel, or the O.C. pill edited and
/// written back (R8), shows up in the next emission without a recount
/// being asked for.
///
/// The stream is the repository's own watch, so it ends when the
/// repository is disposed.
class WatchSpacingCountsUseCase {
  final TradeStoresRepository _repository;
  final Trades _trades;

  /// Creates the use case over the repository that holds the spacings.
  WatchSpacingCountsUseCase({
    required this._repository,
    this._trades = const Trades(),
  });

  /// The members along [span] at each stored spacing, as the store is now
  /// and after every change.
  Stream<List<SpacingCount>> call({required Length span}) =>
      _repository.watchSpacings().map(
        (spacings) => _trades.spacingCountsFor(span, [
          for (final stored in spacings) stored.spacing,
        ]),
      );
}
