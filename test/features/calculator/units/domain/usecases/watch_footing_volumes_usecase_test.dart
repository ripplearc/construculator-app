import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_footing_volumes_usecase.dart';
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
  late WatchFootingVolumesUseCase useCase;
  const formatter = QuantityFormatter();
  const twentyTwoFeet = Length(22 * Length.ticksPerFoot, unit: Unit.foot);

  StoredSize crossSection(int width, int height) => StoredSize(
    store: SizeStore.footing,
    width: Length(width * Length.ticksPerInch, unit: Unit.inch),
    height: Length(height * Length.ticksPerInch, unit: Unit.inch),
    position: 0,
  );

  List<String> texts(List<FootingVolume> volumes) => [
    for (final volume in volumes)
      '${FootingVolume.offerKey}: ${formatter.format(volume.volume)} '
          '(${formatter.formatStoredLength(volume.crossSection.width)} x '
          '${formatter.formatStoredLength(volume.crossSection.height)})',
  ];

  const appendixBFootings = [
    'Footing: 0.72yd³ (16in x 8in)',
    'Footing: 2.44yd³ (24in x 18in)',
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
    useCase = WatchFootingVolumesUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchFootingVolumesUseCase', () {
    test('S45: 22ft of footing over the Appendix B cross-sections', () async {
      final volumes = await useCase(
        length: twentyTwoFeet,
        system: MeasurementSystem.imperial,
      ).first;
      expect(texts(volumes), appendixBFootings);
    });

    test('the footing store has the same cross-sections under Metric, and '
        'the volume follows the System of units setting whatever unit the '
        'length was typed in (R1, D1): 7m reads in m³ under Metric, 22ft '
        'too, and 7m in yd³ under Imperial', () async {
      const sevenMetres = Length.exact(Rational(70000, 254), unit: Unit.metre);
      Future<List<String>> volumesOf(
        Length length,
        MeasurementSystem system,
      ) async => [
        for (final volume in await useCase(
          length: length,
          system: system,
        ).first)
          QuantityFormatter(
            preferences: CalculatorPreferences(system: system),
          ).format(volume.volume),
      ];
      expect(await volumesOf(sevenMetres, MeasurementSystem.metric), [
        '0.58m³',
        '1.95m³',
      ]);
      expect(await volumesOf(twentyTwoFeet, MeasurementSystem.metric), [
        '0.55m³',
        '1.87m³',
      ]);
      expect(await volumesOf(sevenMetres, MeasurementSystem.imperial), [
        '0.76yd³',
        '2.55yd³',
      ]);
    });

    test('re-emits when a cross-section is added or edited in the '
        'store', () async {
      final stream = useCase(
        length: twentyTwoFeet,
        system: MeasurementSystem.imperial,
      );
      final expectation = expectLater(
        stream.map(texts),
        emitsInOrder([
          appendixBFootings,
          [...appendixBFootings, 'Footing: 0.81yd³ (12in x 12in)'],
          [...appendixBFootings, 'Footing: 0.2yd³ (12in x 3in)'],
        ]),
      );
      final added = await repository.addSize(crossSection(12, 12));
      final stored = added.fold((failure) => throw failure, (size) => size);
      await repository.updateSize(
        stored.copyWith(
          height: const Length(3 * Length.ticksPerInch, unit: Unit.inch),
        ),
      );
      await expectation;
    });

    test(
      'a length the rules refuse takes no concrete from any store',
      () async {
        final volumes = await useCase(
          length: const Length(0, unit: Unit.foot),
          system: MeasurementSystem.imperial,
        ).first;
        expect(volumes, isEmpty);
      },
    );

    test('a store whose defaults were all deleted takes no concrete', () async {
      for (final seed in TradeStoreSeeds.sizes(
        SizeStore.footing,
        MeasurementSystem.imperial,
      )) {
        await repository.deleteSize(seed);
      }
      final volumes = await useCase(
        length: twentyTwoFeet,
        system: MeasurementSystem.imperial,
      ).first;
      expect(volumes, isEmpty);
    });

    test('is bound in the calculator module as a fresh instance', () {
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      addTearDown(Modular.destroy);
      final first = Modular.get<WatchFootingVolumesUseCase>();
      expect(first, isA<WatchFootingVolumesUseCase>());
      expect(first, isNot(same(Modular.get<WatchFootingVolumesUseCase>())));
    });
  });
}
