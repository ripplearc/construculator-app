import 'package:construculator/features/calculator/calculator_module.dart';
import 'package:construculator/features/calculator/data/data_source/powersync_local_trade_stores_data_source.dart';
import 'package:construculator/features/calculator/data/repositories/trade_stores_repository_impl.dart';
import 'package:construculator/features/calculator/domain/entities/trade_store_entities.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_fence_count_usecase.dart';
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
  late WatchFenceCountUseCase useCase;
  const formatter = QuantityFormatter();
  const seventyFiveFeet = Length(75 * Length.ticksPerFoot, unit: Unit.foot);
  const tenFeet = Length(10 * Length.ticksPerFoot, unit: Unit.foot);

  String text(FenceCount? fence) {
    if (fence == null) return 'nothing';
    return '${FenceCount.postsKey} ${formatter.format(fence.postsValue)} '
        '(O.C.: ${formatter.format(fence.onCentre)}, '
        'Rails/section: ${fence.railsPerSection}); '
        '${FenceCount.railsOfferKey}: ${formatter.format(fence.railsValue)}';
  }

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
    useCase = WatchFenceCountUseCase(repository: repository);
  });

  tearDown(() async {
    repository.dispose();
    await database.closeChanges();
  });

  group('WatchFenceCountUseCase', () {
    test('S44: 75ft of fence at the Appendix B fence, 8ft on centre with '
        '3 rails per section', () async {
      final fence = await useCase(length: seventyFiveFeet).first;
      expect(
        text(fence),
        'Fence posts 11 (O.C.: 8ft, Rails/section: 3); Rails: 30',
      );
    });

    test('re-emits when the O.C. or the rails per section are written '
        'back from a pill', () async {
      final expectation = expectLater(
        useCase(length: seventyFiveFeet).map(text),
        emitsInOrder([
          'Fence posts 11 (O.C.: 8ft, Rails/section: 3); Rails: 30',
          'Fence posts 9 (O.C.: 10ft, Rails/section: 3); Rails: 24',
          'Fence posts 9 (O.C.: 10ft, Rails/section: 2); Rails: 16',
        ]),
      );
      final updated = await repository.updateFence(
        const FenceConfiguration(onCentre: tenFeet, railsPerSection: 3),
      );
      final stored = updated.fold((failure) => throw failure, (fence) => fence);
      await repository.updateFence(stored.copyWith(railsPerSection: 2));
      await expectation;
    });

    test('a length the rules refuse is no fence', () async {
      final fence = await useCase(
        length: const Length(0, unit: Unit.foot),
      ).first;
      expect(fence, isNull);
    });

    test('is bound in the calculator module as a fresh instance', () {
      Modular.init(CalculatorModule(FakeAppBootstrapFactory.create()));
      addTearDown(Modular.destroy);
      final first = Modular.get<WatchFenceCountUseCase>();
      expect(first, isA<WatchFenceCountUseCase>());
      expect(first, isNot(same(Modular.get<WatchFenceCountUseCase>())));
    });
  });
}
