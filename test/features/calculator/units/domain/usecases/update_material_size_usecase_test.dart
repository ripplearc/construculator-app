import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/update_material_size_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late FakeSupabaseWrapper supabase;
  late TradeStoresRepositoryImpl repository;
  late UpdateMaterialSizeUseCase useCase;
  const formatter = QuantityFormatter();
  const metric = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );

  Length inch(int inches) =>
      Length(inches * Length.ticksPerInch, unit: Unit.inch);

  PieceSize inches(int width, int height, {String? id}) =>
      PieceSize(width: inch(width), height: inch(height), id: id);

  Future<List<StoredSize>> stored(
    SizeStore store, [
    MeasurementSystem system = MeasurementSystem.imperial,
  ]) => repository.watchSizes(store, system).first;

  Future<List<String>> shown(
    SizeStore store, [
    MeasurementSystem system = MeasurementSystem.imperial,
    QuantityFormatter writer = formatter,
  ]) async => [
    for (final size in await stored(store, system))
      writer.formatPieceSize(PieceSize(width: size.width, height: size.height)),
  ];

  setUp(() {
    database = FakeTradeStoresDatabase();
    final clock = FakeClockImpl(DateTime.utc(2026, 11, 26, 10));
    supabase = FakeSupabaseWrapper(clock: clock)..setInternalUserId('user-1');
    // The real chain under test; only the database, the JWT and the clock
    // are faked.
    // ignore: no_direct_instantiation
    repository = TradeStoresRepositoryImpl(
      // ignore: no_direct_instantiation
      dataSource: PowerSyncLocalTradeStoresDataSource(database: database),
      supabaseWrapper: supabase,
      clock: clock,
    );
    // ignore: no_direct_instantiation
    useCase = UpdateMaterialSizeUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('UpdateMaterialSizeUseCase (rule 4.7: "Update rewrites the stored '
      'row the pill came from")', () {
    test('rewrites an Appendix B sheet size in its place, 48in x 96in to '
        '48in x 100in, and answers the size as stored (walkthrough 19.1; '
        'row 220)', () async {
      final updated = await useCase(
        trade: Trade.drywall,
        size: inches(48, 96, id: 'sheet_48x96in'),
        width: inch(48),
        height: inch(100),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.sheet), [
        '48in x 100in',
        '48in x 108in',
        '48in x 120in',
      ]);
      final row = updated.getRightOrNull()!;
      expect((row.width, row.height), (inch(48), inch(100)));
      expect(row, (await stored(SizeStore.sheet)).first);
    });

    test('rewrites the width and the height each to its own measure', () async {
      await useCase(
        trade: Trade.drywall,
        size: inches(48, 108, id: 'sheet_48x108in'),
        width: inch(54),
        height: inch(144),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.sheet), [
        '48in x 96in',
        '54in x 144in',
        '48in x 120in',
      ]);
    });

    test('rewrites the row a size is named by, of two rows with one size: '
        'the added one changes and the default stays', () async {
      await repository.addSize(
        StoredSize(
          store: SizeStore.sheet,
          width: inch(48),
          height: inch(96),
          position: 0,
        ),
      );
      final added = (await stored(SizeStore.sheet)).last;

      await useCase(
        trade: Trade.drywall,
        size: inches(48, 96, id: added.id),
        width: inch(48),
        height: inch(100),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.sheet), [
        '48in x 96in',
        '48in x 108in',
        '48in x 120in',
        '48in x 100in',
      ]);
      expect((await stored(SizeStore.sheet)).last.id, added.id);
    });

    test('a size with no name rewrites the row with its measure', () async {
      await useCase(
        trade: Trade.drywall,
        size: inches(48, 120),
        width: inch(48),
        height: inch(144),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.sheet), [
        '48in x 96in',
        '48in x 108in',
        '48in x 144in',
      ]);
    });

    test('a size the store no longer holds is added back as a new row, '
        'after the last one (row 409)', () async {
      final first = (await stored(SizeStore.sheet)).first;
      await repository.deleteSize(first);

      final updated = await useCase(
        trade: Trade.drywall,
        size: inches(48, 96, id: first.seed),
        width: inch(48),
        height: inch(100),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.sheet), [
        '48in x 108in',
        '48in x 120in',
        '48in x 100in',
      ]);
      expect(updated.getRightOrNull()!.id, isNotNull);
    });

    test('a masonry piece is rewritten in the masonry store, and one added '
        'back goes there too', () async {
      await useCase(
        trade: Trade.masonry,
        size: inches(8, 16),
        width: inch(6),
        height: inch(6),
        system: MeasurementSystem.imperial,
      );
      await useCase(
        trade: Trade.masonry,
        size: inches(1, 2, id: 'a size no store holds'),
        width: inch(3),
        height: inch(5),
        system: MeasurementSystem.imperial,
      );

      expect(await shown(SizeStore.masonry), [
        '6in x 6in',
        '4in x 8in',
        '3in x 5in',
      ]);
      expect(await shown(SizeStore.sheet), hasLength(3));
    });

    test('under Metric the metric default is the one rewritten, and the '
        'Imperial sizes stay', () async {
      final defaults = await stored(SizeStore.sheet, MeasurementSystem.metric);

      await useCase(
        trade: Trade.drywall,
        size: PieceSize(
          width: defaults.first.width,
          height: defaults.first.height,
          id: defaults.first.seed,
        ),
        width: defaults.first.width,
        height: defaults.last.height,
        system: MeasurementSystem.metric,
      );

      expect(
        (await shown(SizeStore.sheet, MeasurementSystem.metric, metric)).first,
        '1200mm x 3000mm',
      );
      expect((await shown(SizeStore.sheet)).first, '48in x 96in');
    });

    test(
      'with nobody signed in the store refuses and nothing changes',
      () async {
        supabase.setInternalUserId(null);

        final updated = await useCase(
          trade: Trade.drywall,
          size: inches(48, 96, id: 'sheet_48x96in'),
          width: inch(48),
          height: inch(100),
          system: MeasurementSystem.imperial,
        );

        expect(updated.isLeft(), isTrue);
        supabase.setInternalUserId('user-1');
        expect((await shown(SizeStore.sheet)).first, '48in x 96in');
      },
    );
  });
}
