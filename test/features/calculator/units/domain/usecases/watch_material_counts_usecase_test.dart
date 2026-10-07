import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_material_counts_usecase.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../helpers/fake_trade_stores_database.dart';

void main() {
  late FakeTradeStoresDatabase database;
  late TradeStoresRepositoryImpl repository;
  late WatchMaterialCountsUseCase useCase;
  const formatter = QuantityFormatter();
  const squareTicksPerSquareFoot =
      Area.squareTicksPerSquareInch * Area.squareInchesPerSquareFoot;
  const area180 = Area(180.0 * squareTicksPerSquareFoot);

  StoredSize inches(SizeStore store, int width, int height, int position) =>
      StoredSize(
        store: store,
        system: MeasurementSystem.imperial,
        width: Length(width * Length.ticksPerInch, unit: Unit.inch),
        height: Length(height * Length.ticksPerInch, unit: Unit.inch),
        position: position,
      );

  List<String> texts(List<TradeCount> counts) => [
    for (final count in counts)
      '${count.trade.offerKey}: ${formatter.format(count.value)} '
          '(${formatter.formatStoredLength(count.size.width)} x '
          '${formatter.formatStoredLength(count.size.height)})',
  ];

  setUp(() {
    database = FakeTradeStoresDatabase();
    // The real chain under test; only the database is faked.
    // ignore: no_direct_instantiation
    repository = TradeStoresRepositoryImpl(
      // ignore: no_direct_instantiation
      dataSource: PowerSyncLocalTradeStoresDataSource(database: database),
    );
    // ignore: no_direct_instantiation
    useCase = WatchMaterialCountsUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchMaterialCountsUseCase', () {
    test('S02: 180ft² of drywall over the seeded sheet sizes', () async {
      await repository.seedDefaults();
      final counts = await useCase(
        trade: Trade.drywall,
        area: area180,
        system: MeasurementSystem.imperial,
      ).first;
      expect(texts(counts), [
        'Drywall: 5.63 (48in x 96in)',
        'Drywall: 5 (48in x 108in)',
        'Drywall: 4.5 (48in x 120in)',
      ]);
    });

    test('S43: 143ft² of masonry over the seeded piece sizes', () async {
      await repository.seedDefaults();
      final counts = await useCase(
        trade: Trade.masonry,
        area: const Area(143.0 * squareTicksPerSquareFoot),
        system: MeasurementSystem.imperial,
      ).first;
      expect(texts(counts), [
        'Masonry: 160.88 (8in x 16in)',
        'Masonry: 643.5 (4in x 8in)',
      ]);
    });

    test('reads the store of the unit system asked for', () async {
      await repository.seedDefaults();
      final counts = await useCase(
        trade: Trade.drywall,
        area: area180,
        system: MeasurementSystem.metric,
      ).first;
      const metric = QuantityFormatter(
        preferences: CalculatorPreferences(system: MeasurementSystem.metric),
      );
      expect(
        [
          for (final count in counts)
            '${metric.format(count.value)} '
                '(${metric.formatStoredLength(count.size.width)} x '
                '${metric.formatStoredLength(count.size.height)})',
        ],
        [
          '5.81 (1200mm x 2400mm)',
          '5.16 (1200mm x 2700mm)',
          '4.64 (1200mm x 3000mm)',
        ],
      );
    });

    test('re-emits when a size is added or edited in the store', () async {
      final stream = useCase(
        trade: Trade.drywall,
        area: area180,
        system: MeasurementSystem.imperial,
      );
      final expectation = expectLater(
        stream.map(texts),
        emitsInOrder([
          <String>[],
          ['Drywall: 5.63 (48in x 96in)'],
          ['Drywall: 5.81 (47.23in x 94.48in)'],
        ]),
      );
      final added = await repository.addSize(
        inches(SizeStore.sheet, 48, 96, 0),
      );
      final stored = added.fold((failure) => throw failure, (size) => size);
      await repository.updateSize(
        stored.copyWith(
          width: const Length(3023, unit: Unit.inch),
          height: const Length(6047, unit: Unit.inch),
        ),
      );
      await expectation;
    });

    test('an empty store counts nothing', () async {
      final counts = await useCase(
        trade: Trade.masonry,
        area: area180,
        system: MeasurementSystem.imperial,
      ).first;
      expect(counts, isEmpty);
    });

    test('is bound in the calculator module as a fresh instance', () {
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      addTearDown(Modular.destroy);
      final first = Modular.get<WatchMaterialCountsUseCase>();
      expect(first, isA<WatchMaterialCountsUseCase>());
      expect(first, isNot(same(Modular.get<WatchMaterialCountsUseCase>())));
    });
  });
}
