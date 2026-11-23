import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../../utils/fake_cost_items_database.dart';

void main() {
  group('CostItemRepositoryImpl on the phone', () {
    late FakeCostItemsDatabase database;
    late FakeSupabaseWrapper supabase;
    late CostItemRepository repository;

    MaterialCostItem line({String id = 'line-1', String name = 'Cement'}) =>
        MaterialCostItem(
          id: id,
          estimateId: 'estimate-1',
          itemName: name,
          calculation: const {'unit_price': 10.0, 'quantity': 10.0},
          itemTotalCost: 100.0,
          createdAt: DateTime.utc(2026, 11, 14),
          updatedAt: DateTime.utc(2026, 11, 14),
          currency: 'USD',
          unitPrice: const Money(amount: 10.0),
          quantity: const Quantity(value: 10.0, unit: Unit.bags),
          rateStatus: RateStatus.ownRateUnconfirmed,
          quantityProvenance: QuantityProvenance.manual,
        );

    setUp(() {
      database = FakeCostItemsDatabase();
      supabase = FakeSupabaseWrapper(clock: FakeClockImpl());
      Modular.init(
        EstimationModule(
          FakeAppBootstrapFactory.create(supabaseWrapper: supabase),
        ),
      );
      Modular.replaceInstance<PowerSyncDatabaseWrapper>(database);
      repository = Modular.get<CostItemRepository>();
    });

    tearDown(Modular.destroy);

    group('addCostItemOnPhone', () {
      test('returns the line it saved', () async {
        final result = await repository.addCostItemOnPhone(line());

        expect(result.getRightOrNull(), line());
      });

      test('keeps the line on the phone under its id', () async {
        await repository.addCostItemOnPhone(line(id: 'line-7'));

        expect(database.rows.single['id'], 'line-7');
      });

      test('never asks the server', () async {
        await repository.addCostItemOnPhone(line());

        expect(supabase.getMethodCallsFor('insert'), isEmpty);
        expect(supabase.getMethodCallsFor('upsert'), isEmpty);
        expect(supabase.getMethodCallsFor('update'), isEmpty);
      });

      test('leaves one row when the same line is added twice', () async {
        await repository.addCostItemOnPhone(line());
        await repository.addCostItemOnPhone(line(name: 'Cement 50 lb'));

        expect(database.rows.single['item_name'], 'Cement 50 lb');
      });

      test('refuses a line with no id and writes nothing', () async {
        final result = await repository.addCostItemOnPhone(line(id: ''));

        expect(
          result.getLeftOrNull(),
          const EstimationFailure(
            errorType: EstimationErrorType.unexpectedError,
          ),
        );
        expect(database.executeCalls, isEmpty);
      });

      test('returns a database failure when the phone cannot write', () async {
        database.executeError = StateError('disk full');

        final result = await repository.addCostItemOnPhone(line());

        expect(
          result.getLeftOrNull(),
          const EstimationFailure(
            errorType: EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      });
    });

    group('watchNotSyncedCostItemIds', () {
      test('lists a line waiting to upload', () async {
        await repository.addCostItemOnPhone(line());

        await expectLater(
          repository
              .watchNotSyncedCostItemIds('estimate-1')
              .map((result) => result.getRightOrNull()),
          emits({'line-1'}),
        );
      });

      test('drops the line once its upload finishes', () async {
        await repository.addCostItemOnPhone(line());

        final ids = expectLater(
          repository
              .watchNotSyncedCostItemIds('estimate-1')
              .map((result) => result.getRightOrNull()),
          emitsInOrder([
            {'line-1'},
            <String>{},
          ]),
        );
        database.finishUpload('line-1');

        await ids;
      });

      test('reports a failed read as a failure and keeps watching', () async {
        await repository.addCostItemOnPhone(line());

        final results = expectLater(
          repository
              .watchNotSyncedCostItemIds('estimate-1')
              .map((result) => result.isLeft()),
          emitsInOrder([false, true, false]),
        );
        database.failWatches(StateError('database locked'));
        database.finishUpload('line-1');

        await results;
      });
    });
  });
}
