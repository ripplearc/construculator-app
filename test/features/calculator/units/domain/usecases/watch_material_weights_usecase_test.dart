import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_material_weights_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late TradeStoresRepositoryImpl repository;
  late WatchMaterialWeightsUseCase useCase;
  const formatter = QuantityFormatter();
  const elevenCubicYards = Volume(11.0 * 27, unit: Unit.yard);

  List<String> texts(List<MaterialWeight> weights) => [
    for (final weight in weights)
      '${formatter.format(weight.weight)} (${weight.density.name}, '
          '${formatter.formatDensity(weight.density.poundsPerCubicYard)})',
  ];

  const appendixBWeights = [
    '22.28 ton (concrete, 4,050lbs/yd³)',
    '16.5 ton (gravel, 3,000lbs/yd³)',
    '14.85 ton (sand, 2,700lbs/yd³)',
  ];

  setUp(() {
    database = FakeTradeStoresDatabase();
    final clock = FakeClockImpl(DateTime.utc(2026, 11, 16, 10));
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
    useCase = WatchMaterialWeightsUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchMaterialWeightsUseCase', () {
    test('S48: 11yd³ over the Appendix B densities, concrete first', () async {
      final weights = await useCase(
        volume: elevenCubicYards,
        system: MeasurementSystem.imperial,
      ).first;
      expect(texts(weights), appendixBWeights);
    });

    test('under the metric system the weights are in metric tons', () async {
      final weights = await useCase(
        volume: elevenCubicYards,
        system: MeasurementSystem.metric,
      ).first;
      expect(
        [for (final weight in weights) formatter.format(weight.weight)],
        ['20.21 m tons', '14.97 m tons', '13.47 m tons'],
      );
    });

    test('S49, row 244: re-emits when a density is edited or a material '
        'is added in the store', () async {
      final expectation = expectLater(
        useCase(
          volume: elevenCubicYards,
          system: MeasurementSystem.imperial,
        ).map(texts),
        emitsInOrder([
          appendixBWeights,
          [
            appendixBWeights[0],
            '17.6 ton (gravel, 3,200lbs/yd³)',
            appendixBWeights[2],
          ],
          [
            appendixBWeights[0],
            '17.6 ton (gravel, 3,200lbs/yd³)',
            appendixBWeights[2],
            '11 ton (topsoil, 2,000lbs/yd³)',
          ],
        ]),
      );
      final gravel = TradeStoreSeeds.densities[1];
      await repository.updateDensity(gravel.copyWith(poundsPerCubicYard: 3200));
      await repository.addDensity(
        const StoredDensity(
          name: 'topsoil',
          poundsPerCubicYard: 2000,
          position: 0,
        ),
      );
      await expectation;
    });

    test('a volume the rules refuse weighs nothing in any material', () async {
      final weights = await useCase(
        volume: const Volume(0),
        system: MeasurementSystem.imperial,
      ).first;
      expect(weights, isEmpty);
    });

    test('a store whose defaults were all deleted weighs nothing', () async {
      for (final seed in TradeStoreSeeds.densities) {
        await repository.deleteDensity(seed);
      }
      final weights = await useCase(
        volume: elevenCubicYards,
        system: MeasurementSystem.imperial,
      ).first;
      expect(weights, isEmpty);
    });

    test('is bound in the calculator module as a fresh instance', () {
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      addTearDown(Modular.destroy);
      final first = Modular.get<WatchMaterialWeightsUseCase>();
      expect(first, isA<WatchMaterialWeightsUseCase>());
      expect(first, isNot(same(Modular.get<WatchMaterialWeightsUseCase>())));
    });
  });
}
