import 'dart:async';

import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/repositories/trade_stores_repository.dart';
import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Fake [TradeStoresRepository] for testing the calculator bloc: holds every
/// store in memory, mints ids by counting, and lets a test fail the next
/// write.
class FakeTradeStoresRepository implements TradeStoresRepository {
  /// Every stored size, in insertion order.
  final List<StoredSize> sizes = [];

  /// Every stored spacing, in insertion order.
  final List<StoredSpacing> spacings = [];

  /// The fence; Appendix B's until changed.
  FenceConfiguration fence = TradeStoreSeeds.fence;

  /// The rates by unit; Appendix B's until changed.
  final Map<RateUnit, StoredRate> rates = {
    for (final rate in TradeStoreSeeds.rates) rate.unit: rate,
  };

  /// Every stored density, in insertion order.
  final List<StoredDensity> densities = [];

  /// The failure every write answers with while set.
  Failure? writeFailure;

  /// How many times [seedDefaults] was called.
  int seedCalls = 0;

  final _changes = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Future<Either<Failure, void>> seedDefaults() async {
    seedCalls += 1;
    if (sizes.isEmpty) {
      for (final size in TradeStoreSeeds.sizes) {
        sizes.add(size.copyWith(id: _id()));
      }
    }
    if (spacings.isEmpty) {
      for (final spacing in TradeStoreSeeds.spacings) {
        spacings.add(spacing.copyWith(id: _id()));
      }
    }
    if (densities.isEmpty) {
      for (final density in TradeStoreSeeds.densities) {
        densities.add(density.copyWith(id: _id()));
      }
    }
    _notify();
    return const Right(null);
  }

  @override
  Stream<List<StoredSize>> watchSizes(
    SizeStore store,
    MeasurementSystem system,
  ) => _watch(
    () =>
        sizes
            .where((size) => size.store == store && size.system == system)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position)),
  );

  @override
  Future<Either<Failure, StoredSize>> addSize(StoredSize size) => _write(() {
    final stored = size.copyWith(id: _id());
    sizes.add(stored);
    return stored;
  });

  @override
  Future<Either<Failure, StoredSize>> updateSize(StoredSize size) =>
      _write(() => _replace(sizes, size, (s) => s.id == size.id));

  @override
  Future<Either<Failure, void>> deleteSize(String id) =>
      _write(() => _remove(sizes, (s) => s.id == id));

  @override
  Stream<List<StoredSpacing>> watchSpacings() => _watch(
    () => spacings.toList()..sort((a, b) => a.position.compareTo(b.position)),
  );

  @override
  Future<Either<Failure, StoredSpacing>> addSpacing(StoredSpacing spacing) =>
      _write(() {
        final stored = spacing.copyWith(id: _id());
        spacings.add(stored);
        return stored;
      });

  @override
  Future<Either<Failure, StoredSpacing>> updateSpacing(StoredSpacing spacing) =>
      _write(() => _replace(spacings, spacing, (s) => s.id == spacing.id));

  @override
  Future<Either<Failure, void>> deleteSpacing(String id) =>
      _write(() => _remove(spacings, (s) => s.id == id));

  @override
  Stream<FenceConfiguration> watchFence() => _watch(() => fence);

  @override
  Future<Either<Failure, FenceConfiguration>> updateFence(
    FenceConfiguration fence,
  ) => _write(() => this.fence = fence);

  @override
  Stream<List<StoredRate>> watchRates() => _watch(() => rates.values.toList());

  @override
  Future<Either<Failure, StoredRate>> updateRate(StoredRate rate) =>
      _write(() => rates[rate.unit] = rate);

  @override
  Stream<List<StoredDensity>> watchDensities() => _watch(
    () => densities.toList()..sort((a, b) => a.position.compareTo(b.position)),
  );

  @override
  Future<Either<Failure, StoredDensity>> addDensity(StoredDensity density) =>
      _write(() {
        final stored = density.copyWith(id: _id());
        densities.add(stored);
        return stored;
      });

  @override
  Future<Either<Failure, StoredDensity>> updateDensity(StoredDensity density) =>
      _write(() => _replace(densities, density, (d) => d.id == density.id));

  @override
  Future<Either<Failure, void>> deleteDensity(String id) =>
      _write(() => _remove(densities, (d) => d.id == id));

  /// Puts every store back to empty with nothing failing.
  void reset() {
    sizes.clear();
    spacings.clear();
    densities.clear();
    fence = TradeStoreSeeds.fence;
    rates
      ..clear()
      ..addEntries(TradeStoreSeeds.rates.map((r) => MapEntry(r.unit, r)));
    writeFailure = null;
    seedCalls = 0;
    _notify();
  }

  @override
  void dispose() {
    unawaited(_changes.close());
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

  T _replace<T>(List<T> list, T value, bool Function(T) matches) {
    final index = list.indexWhere(matches);
    if (index < 0) throw StateError('not found');
    list[index] = value;
    return value;
  }

  void _remove<T>(List<T> list, bool Function(T) matches) {
    final index = list.indexWhere(matches);
    if (index < 0) throw StateError('not found');
    list.removeAt(index);
  }
}
