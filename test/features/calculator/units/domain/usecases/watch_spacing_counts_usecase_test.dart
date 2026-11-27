import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/models/trade_store_seeds.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_spacing_counts_usecase.dart';
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
  late WatchSpacingCountsUseCase useCase;
  const formatter = QuantityFormatter();
  // 22ft 8-3/4in, the span of S46.
  const span = Length.exact(Rational(1091, 4), unit: Unit.footInch);

  StoredSpacing spacing(double inches) => StoredSpacing(
    spacing: Length((inches * Length.ticksPerInch).round(), unit: Unit.inch),
    position: 0,
  );

  List<String> texts(List<SpacingCount> counts) => [
    for (final count in counts)
      '${SpacingCount.offerKey} @'
          '${formatter.formatStoredLength(count.spacing)}: '
          '${formatter.format(count.value)}',
  ];

  const appendixBSpacings = ['Qty @16in: 19', 'Qty @24in: 13'];

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
    useCase = WatchSpacingCountsUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchSpacingCountsUseCase', () {
    test('S46: 22ft 8-3/4in over the Appendix B spacings', () async {
      final counts = await useCase(span: span).first;
      expect(texts(counts), appendixBSpacings);
    });

    test('re-emits when a spacing is added or edited in the store', () async {
      final expectation = expectLater(
        useCase(span: span).map(texts),
        emitsInOrder([
          appendixBSpacings,
          [...appendixBSpacings, 'Qty @19.5in: 15'],
          [...appendixBSpacings, 'Qty @12in: 24'],
        ]),
      );
      final added = await repository.addSpacing(spacing(19.5));
      final stored = added.fold((failure) => throw failure, (added) => added);
      await repository.updateSpacing(
        stored.copyWith(
          spacing: const Length(12 * Length.ticksPerInch, unit: Unit.inch),
        ),
      );
      await expectation;
    });

    test('a span the rules refuse has no members at any spacing', () async {
      final counts = await useCase(
        span: const Length(0, unit: Unit.foot),
      ).first;
      expect(counts, isEmpty);
    });

    test('a store whose defaults were all deleted counts nothing', () async {
      for (final seed in TradeStoreSeeds.spacings) {
        await repository.deleteSpacing(seed);
      }
      final counts = await useCase(span: span).first;
      expect(counts, isEmpty);
    });

    test('is bound in the calculator module as a fresh instance', () {
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      addTearDown(Modular.destroy);
      final first = Modular.get<WatchSpacingCountsUseCase>();
      expect(first, isA<WatchSpacingCountsUseCase>());
      expect(first, isNot(same(Modular.get<WatchSpacingCountsUseCase>())));
    });
  });
}
