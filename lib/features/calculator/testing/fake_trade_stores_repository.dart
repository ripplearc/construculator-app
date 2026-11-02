import 'dart:async';

import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Fake [TradeStoresRepository] for testing the calculator bloc: holds every
/// store in memory as the real one shows it — Appendix B's defaults from the
/// start, each with its seed and no id until changed — mints ids by
/// counting, and lets a test fail the next write or sign the user out.
class FakeTradeStoresRepository implements TradeStoresRepository {
  /// Every size on show, defaults and user-added, across the three stores
  /// and both sheet seed sets.
  final List<StoredSize> sizes = [];

  /// Every spacing on show.
  final List<StoredSpacing> spacings = [];

  /// The fence; Appendix B's until changed.
  FenceConfiguration fence = TradeStoreSeeds.fence;

  /// The waste factor of every unit; 0% until changed.
  final List<StoredWaste> waste = [];

  /// Every density on show.
  final List<StoredDensity> densities = [];

  /// The failure every write answers with while set.
  Failure? writeFailure;

  /// Whether a user is signed in; a write with nobody signed in is refused.
  bool signedIn = true;

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  /// Creates a fake showing Appendix B's defaults.
  FakeTradeStoresRepository() {
    _seed();
  }

  @override
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) {
    final seeds = TradeStoreSeeds.sizes(store, system).map((s) => s.seed);
    return _watch(
      () => _inOrder(
        sizes.where(
          (size) =>
              size.store == store &&
              (size.seed == null || seeds.contains(size.seed)),
        ),
        (size) => size.position,
      ),
    );
  }

  @override
  Future<Either<Failure, StoredSize>> addSize(StoredSize size) => _write(() {
    final stored = StoredSize(
      id: _id(),
      store: size.store,
      width: size.width,
      height: size.height,
      position: _after(
        sizes.where((s) => s.store == size.store),
        (s) => s.position,
      ),
    );
    sizes.add(stored);
    return stored;
  });

  @override
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size) =>
      _write(() => _replace(sizes, size, (s) => s.copyWith(id: _id())));

  @override
  Future<Either<Failure, void>> deleteSize(StoredSize size) =>
      _write(() => _remove(sizes, size));

  @override
  Stream<List<StoredSpacing>> watchSpacings() =>
      _watch(() => _inOrder(spacings, (s) => s.position));

  @override
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing) =>
      _write(() {
        final stored = StoredSpacing(
          id: _id(),
          spacing: spacing.spacing,
          position: _after(spacings, (s) => s.position),
        );
        spacings.add(stored);
        return stored;
      });

  @override
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing) =>
      _write(() => _replace(spacings, spacing, (s) => s.copyWith(id: _id())));

  @override
  Future<Either<Failure, void>> deleteSpacing(StoredSpacing spacing) =>
      _write(() => _remove(spacings, spacing));

  @override
  Stream<FenceConfiguration> watchFence() => _watch(() => fence);

  @override
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  ) => _write(() => this.fence = fence);

  @override
  Stream<List<StoredWaste>> watchWaste() => _watch(() => waste.toList());

  @override
  Future<Either<Failure, StoredWaste>> updateWaste(StoredWaste waste) =>
      _write(() {
        this.waste[waste.unit.index] = waste;
        return waste;
      });

  @override
  Stream<List<StoredDensity>> watchDensities() =>
      _watch(() => _inOrder(densities, (d) => d.position));

  @override
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density) =>
      _write(() {
        final stored = StoredDensity(
          id: _id(),
          name: density.name,
          poundsPerCubicYard: density.poundsPerCubicYard,
          position: _after(densities, (d) => d.position),
        );
        densities.add(stored);
        return stored;
      });

  @override
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density) =>
      _write(() => _replace(densities, density, (d) => d.copyWith(id: _id())));

  @override
  Future<Either<Failure, void>> deleteDensity(StoredDensity density) =>
      _write(() => _remove(densities, density));

  /// Puts every store back to Appendix B with nothing failing and the user
  /// signed in.
  void reset() {
    _seed();
    writeFailure = null;
    signedIn = true;
    _notify();
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }

  void _seed() {
    sizes
      ..clear()
      ..addAll([
        for (final store in SizeStore.values)
          ...TradeStoreSeeds.sizes(store, MeasurementSystem.imperial),
        ...TradeStoreSeeds.sizes(SizeStore.sheet, MeasurementSystem.metric),
      ]);
    spacings
      ..clear()
      ..addAll(TradeStoreSeeds.spacings);
    fence = TradeStoreSeeds.fence;
    waste
      ..clear()
      ..addAll(TradeStoreSeeds.waste);
    densities
      ..clear()
      ..addAll(TradeStoreSeeds.densities);
  }

  String _id() => 'fake-${_nextId++}';

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((controller) {
    controller.add(read());
    final subscription = _changes.stream.listen(
      (_) => controller.add(read()),
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });

  Future<Either<Failure, T>> _write<T>(T Function() write) async {
    if (!signedIn) {
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notSignedIn),
      );
    }
    if (writeFailure case final failure?) return Left(failure);
    try {
      final result = write();
      _notify();
      return Right(result);
    } on StateError {
      return const Left(
        CalculatorFailure(errorType: CalculatorErrorType.notFound),
      );
    }
  }

  List<T> _inOrder<T>(Iterable<T> entries, int Function(T) positionOf) =>
      entries.toList()..sort((a, b) => positionOf(a).compareTo(positionOf(b)));

  int _after<T>(Iterable<T> entries, int Function(T) positionOf) =>
      entries.isEmpty
      ? 0
      : entries.map(positionOf).reduce((a, b) => a > b ? a : b) + 1;

  // The entry the given one stands for: the stored row with its id, or the
  // default with its seed.
  int _indexOf<T>(List<T> list, T value) {
    final id = _idOf(value);
    final seed = _seedOf(value);
    if (id != null) return list.indexWhere((e) => _idOf(e) == id);
    if (seed != null) return list.indexWhere((e) => _seedOf(e) == seed);
    return -1;
  }

  T _replace<T>(List<T> list, T value, T Function(T) stored) {
    final index = _indexOf(list, value);
    if (index < 0) throw StateError('not found');
    final replacement = _idOf(value) == null ? stored(value) : value;
    list[index] = replacement;
    return replacement;
  }

  void _remove<T>(List<T> list, T value) {
    final index = _indexOf(list, value);
    if (index < 0) throw StateError('not found');
    list.removeAt(index);
  }

  String? _idOf(Object? entry) => switch (entry) {
    StoredSize(:final id) ||
    StoredSpacing(:final id) ||
    StoredDensity(:final id) => id,
    _ => null,
  };

  String? _seedOf(Object? entry) => switch (entry) {
    StoredSize(:final seed) ||
    StoredSpacing(:final seed) ||
    StoredDensity(:final seed) => seed,
    _ => null,
  };
}
