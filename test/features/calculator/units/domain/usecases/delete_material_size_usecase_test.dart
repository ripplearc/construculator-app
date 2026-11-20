import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_material_size_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late FakeSupabaseWrapper supabase;
  late TradeStoresRepositoryImpl repository;
  late DeleteMaterialSizeUseCase useCase;
  const formatter = QuantityFormatter();
  const metric = QuantityFormatter(
    preferences: CalculatorPreferences(system: MeasurementSystem.metric),
  );

  PieceSize inches(int width, int height) => PieceSize(
    width: Length(width * Length.ticksPerInch, unit: Unit.inch),
    height: Length(height * Length.ticksPerInch, unit: Unit.inch),
  );

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
    useCase = DeleteMaterialSizeUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('DeleteMaterialSizeUseCase', () {
    test(
      'removes an Appendix B sheet size; the others stay in order',
      () async {
        final deleted = await useCase(
          trade: Trade.drywall,
          size: inches(48, 108),
          system: MeasurementSystem.imperial,
        );
        expect(deleted.isRight(), isTrue);
        expect(await shown(SizeStore.sheet), ['48in x 96in', '48in x 120in']);
      },
    );

    test('removes a size the user added', () async {
      await repository.addSize(
        StoredSize(
          store: SizeStore.sheet,
          width: inches(48, 144).width,
          height: inches(48, 144).height,
          position: 0,
        ),
      );
      await useCase(
        trade: Trade.drywall,
        size: inches(48, 144),
        system: MeasurementSystem.imperial,
      );
      expect(await shown(SizeStore.sheet), [
        '48in x 96in',
        '48in x 108in',
        '48in x 120in',
      ]);
    });

    test('removes one of a size the store holds twice', () async {
      await repository.addSize(
        StoredSize(
          store: SizeStore.sheet,
          width: inches(48, 96).width,
          height: inches(48, 96).height,
          position: 0,
        ),
      );
      await useCase(
        trade: Trade.drywall,
        size: inches(48, 96),
        system: MeasurementSystem.imperial,
      );
      expect(await shown(SizeStore.sheet), [
        '48in x 108in',
        '48in x 120in',
        '48in x 96in',
      ]);
    });

    test('masonry removes from the piece sizes, not the sheets', () async {
      await useCase(
        trade: Trade.masonry,
        size: inches(4, 8),
        system: MeasurementSystem.imperial,
      );
      expect(await shown(SizeStore.masonry), ['8in x 16in']);
      expect(await shown(SizeStore.sheet), hasLength(3));
    });

    test('reads the sizes of the unit system asked for', () async {
      final metricSheets = await repository
          .watchSizes(SizeStore.sheet, MeasurementSystem.metric)
          .first;
      await useCase(
        trade: Trade.drywall,
        size: PieceSize(
          width: metricSheets.first.width,
          height: metricSheets.first.height,
        ),
        system: MeasurementSystem.metric,
      );
      expect(await shown(SizeStore.sheet, MeasurementSystem.metric, metric), [
        '1200mm x 2700mm',
        '1200mm x 3000mm',
      ]);
    });

    test('a size the store no longer holds is answered as done and nothing '
        'changes', () async {
      final deleted = await useCase(
        trade: Trade.drywall,
        size: inches(48, 100),
        system: MeasurementSystem.imperial,
      );
      expect(deleted.isRight(), isTrue);
      expect(await shown(SizeStore.sheet), hasLength(3));
    });

    test(
      'with nobody signed in the store refuses and nothing changes',
      () async {
        supabase.setInternalUserId(null);
        final deleted = await useCase(
          trade: Trade.drywall,
          size: inches(48, 96),
          system: MeasurementSystem.imperial,
        );
        expect(deleted.isLeft(), isTrue);
        supabase.setInternalUserId('user-1');
        expect(await shown(SizeStore.sheet), hasLength(3));
      },
    );
  });
}
