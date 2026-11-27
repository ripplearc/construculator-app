import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_trade_stores_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late TradeStoresRepositoryImpl repository;
  late WatchTradeStoresUseCase useCase;
  const formatter = QuantityFormatter();
  const metric = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );

  StoredSize inches(SizeStore store, int width, int height) => StoredSize(
    store: store,
    width: Length(width * Length.ticksPerInch, unit: Unit.inch),
    height: Length(height * Length.ticksPerInch, unit: Unit.inch),
    position: 0,
  );

  List<String> texts(
    List<PieceSize> sizes, [
    QuantityFormatter writer = formatter,
  ]) => [for (final size in sizes) writer.formatPieceSize(size)];

  setUp(() {
    database = FakeTradeStoresDatabase();
    final clock = FakeClockImpl(DateTime.utc(2026, 11, 26, 10));
    // The real chain under test; only the database, the JWT and the clock
    // are faked.
    // ignore: no_direct_instantiation
    repository = TradeStoresRepositoryImpl(
      // ignore: no_direct_instantiation
      dataSource: PowerSyncLocalTradeStoresDataSource(database: database),
      supabaseWrapper: FakeSupabaseWrapper(clock: clock)
        ..setInternalUserId('user-1'),
      clock: clock,
    );
    // ignore: no_direct_instantiation
    useCase = WatchTradeStoresUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchTradeStoresUseCase', () {
    test('reads Appendix B\'s sheet sizes and masonry sizes as one snapshot, '
        'each piece named by the default it stands in for', () async {
      final stores = await useCase(system: MeasurementSystem.imperial).first;

      expect(texts(stores.sheetSizes), [
        '48in x 96in',
        '48in x 108in',
        '48in x 120in',
      ]);
      expect(texts(stores.masonrySizes), ['8in x 16in', '4in x 8in']);
      expect([
        for (final size in stores.sheetSizes) size.id,
      ], everyElement(isNotNull));
      expect({for (final size in stores.sheetSizes) size.id}, hasLength(3));
    });

    test('under Metric the sheet sizes are the metric defaults, and the '
        'masonry sizes are the one set there is', () async {
      final stores = await useCase(system: MeasurementSystem.metric).first;

      expect(texts(stores.sheetSizes, metric), [
        '1200mm x 2400mm',
        '1200mm x 2700mm',
        '1200mm x 3000mm',
      ]);
      expect(stores.masonrySizes, hasLength(2));
    });

    test('a size added to either store is in the next snapshot, after the '
        'last one, named by its stored row', () async {
      final withASheet = expectLater(
        useCase(system: MeasurementSystem.imperial),
        emitsThrough(
          isA<TradeStores>().having(
            (stores) => texts(stores.sheetSizes),
            'sheet sizes',
            ['48in x 96in', '48in x 108in', '48in x 120in', '48in x 100in'],
          ),
        ),
      );

      final added = await repository.addSize(inches(SizeStore.sheet, 48, 100));
      await withASheet;

      final withAPiece = expectLater(
        useCase(system: MeasurementSystem.imperial),
        emitsThrough(
          isA<TradeStores>().having(
            (stores) => texts(stores.masonrySizes),
            'masonry sizes',
            ['8in x 16in', '4in x 8in', '6in x 6in'],
          ),
        ),
      );
      await repository.addSize(inches(SizeStore.masonry, 6, 6));
      await withAPiece;

      final stores = await useCase(system: MeasurementSystem.imperial).first;
      expect(stores.sheetSizes.last.id, added.getRightOrNull()!.id);
    });

    test(
      'two stored rows of one size stay two pieces with two names',
      () async {
        await repository.addSize(inches(SizeStore.sheet, 48, 96));

        final stores = await useCase(system: MeasurementSystem.imperial).first;

        final twins = [
          for (final size in stores.sheetSizes)
            if (formatter.formatPieceSize(size) == '48in x 96in') size.id,
        ];
        expect(twins, hasLength(2));
        expect(twins.toSet(), hasLength(2));
      },
    );

    test('a write that changes neither store emits no second snapshot of '
        'the same stores', () async {
      final seen = <TradeStores>[];
      final subscription = useCase(
        system: MeasurementSystem.imperial,
      ).listen(seen.add);
      addTearDown(subscription.cancel);
      final changed = expectLater(
        useCase(system: MeasurementSystem.imperial),
        emitsThrough(
          isA<TradeStores>().having(
            (stores) => stores.sheetSizes,
            'sheet sizes',
            hasLength(4),
          ),
        ),
      );

      await repository.addSpacing(
        const StoredSpacing(
          spacing: Length(12 * Length.ticksPerInch, unit: Unit.inch),
          position: 0,
        ),
      );
      await repository.addSize(inches(SizeStore.sheet, 48, 100));
      await changed;

      expect(
        [for (final stores in seen) stores.sheetSizes.length],
        [3, 4],
        reason: 'the spacing write re-read the sizes and emitted nothing new',
      );
    });
  });
}
