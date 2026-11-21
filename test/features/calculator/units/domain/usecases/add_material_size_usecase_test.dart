import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/add_material_size_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late FakeSupabaseWrapper supabase;
  late TradeStoresRepositoryImpl repository;
  late AddMaterialSizeUseCase useCase;
  const formatter = QuantityFormatter();
  const metric = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );

  Length feet(int value) =>
      Length(value * 12 * Length.ticksPerInch, unit: Unit.foot);

  Future<List<String>> shown(
    SizeStore store, [
    MeasurementSystem system = MeasurementSystem.imperial,
    QuantityFormatter writer = formatter,
  ]) async => [
    for (final size in await repository.watchSizes(store, system).first)
      writer.formatPieceSize(PieceSize(width: size.width, height: size.height)),
  ];

  setUp(() {
    database = FakeTradeStoresDatabase();
    final clock = FakeClockImpl(DateTime.utc(2026, 11, 20, 10));
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
    useCase = AddMaterialSizeUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('AddMaterialSizeUseCase', () {
    test('4ft by 12ft goes after the last sheet size as 48in x 144in '
        '(walkthrough 11.4)', () async {
      final added = await useCase(
        trade: Trade.drywall,
        width: feet(4),
        height: feet(12),
      );
      expect(added.isRight(), isTrue);
      expect(await shown(SizeStore.sheet), [
        '48in x 96in',
        '48in x 108in',
        '48in x 120in',
        '48in x 144in',
      ]);
    });

    test(
      'an added size shows under Metric too, in millimetres (term 2.16)',
      () async {
        await useCase(trade: Trade.drywall, width: feet(4), height: feet(12));
        expect(
          (await shown(SizeStore.sheet, MeasurementSystem.metric, metric)).last,
          '1219mm x 3658mm',
        );
      },
    );

    test('masonry adds to the piece sizes, not the sheets', () async {
      await useCase(trade: Trade.masonry, width: feet(1), height: feet(2));
      expect((await shown(SizeStore.masonry)).last, '12in x 24in');
      expect(await shown(SizeStore.sheet), hasLength(3));
    });

    test(
      'with nobody signed in the store refuses and nothing is added',
      () async {
        supabase.setInternalUserId(null);
        final added = await useCase(
          trade: Trade.drywall,
          width: feet(4),
          height: feet(12),
        );
        expect(added.isLeft(), isTrue);
        supabase.setInternalUserId('user-1');
        expect(await shown(SizeStore.sheet), hasLength(3));
      },
    );
  });
}
