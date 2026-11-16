import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/trades.dart';

/// The posts and rails a length of fence needs, read through the
/// trade-stores repository (UX Design Doc Section 9, "Fence"; requirement
/// R9): one [FenceCount] over the stored fence configuration — its O.C.
/// and rails per section, Appendix B's 8ft and 3 until the user changes
/// them — re-emitted whenever the configuration changes, so an O.C. or
/// Rails/section pill edited and written back (R8) shows up in the next
/// emission without a recount being asked for.
///
/// The stream is the repository's own watch, so it ends when the
/// repository is disposed.
class WatchFenceCountUseCase {
  final TradeStoresRepository _repository;
  final Trades _trades;

  /// Creates the use case over the repository that holds the fence.
  WatchFenceCountUseCase({
    required this._repository,
    this._trades = const Trades(),
  });

  /// The fence along [length] at the stored configuration, as it is now
  /// and after every change; `null` while the rules refuse the length (a
  /// length of zero or less), which the screen never lets through.
  Stream<FenceCount?> call({required Length length}) =>
      _repository.watchFence().map(
        (fence) => _trades.fenceFor(
          length,
          onCentre: fence.onCentre,
          railsPerSection: fence.railsPerSection,
        ),
      );
}
