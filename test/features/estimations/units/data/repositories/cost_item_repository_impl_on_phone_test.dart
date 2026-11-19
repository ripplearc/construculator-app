import 'dart:convert';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_database_wrapper.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
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

    group('getEstimateItemsTotal', () {
      void seedServer(Map<String, num> totalsById) {
        supabase.addTableData('cost_items', [
          for (final entry in totalsById.entries)
            {
              'id': entry.key,
              'estimate_id': 'estimate-1',
              'item_total_cost': entry.value,
            },
        ]);
      }

      test('counts a line saved on the phone that the server lacks', () async {
        seedServer({'server-1': 2000});
        await repository.addCostItemOnPhone(line());

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 2100);
      });

      test('counts a line the server and the phone both have once', () async {
        seedServer({'line-1': 100});
        await repository.addCostItemOnPhone(line());

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 100);
      });

      test('counts the phone\'s total for a line both have', () async {
        seedServer({'line-1': 90});
        await repository.addCostItemOnPhone(line());

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 100);
      });
      test(
        'returns the connection failure, not a total of the phone\'s lines, when '
        'the server cannot be reached',
        () async {
          seedServer({'server-1': 2000});
          await repository.addCostItemOnPhone(line());
          supabase.shouldThrowOnSelectMatch = true;
          supabase.selectMatchExceptionType = SupabaseExceptionType.socket;

          final result = await repository.getEstimateItemsTotal('estimate-1');

          expect(
            result.getLeftOrNull(),
            const EstimationFailure(
              errorType: EstimationErrorType.connectionError,
            ),
          );
        },
      );
      test(
        'returns the timeout failure, not a total of the phone\'s lines, when '
        'the server times out',
        () async {
          await repository.addCostItemOnPhone(line());
          supabase.shouldThrowOnSelectMatch = true;
          supabase.selectMatchExceptionType = SupabaseExceptionType.timeout;

          final result = await repository.getEstimateItemsTotal('estimate-1');

          expect(
            result.getLeftOrNull(),
            const EstimationFailure(
              errorType: EstimationErrorType.timeoutError,
            ),
          );
        },
      );
      String refusedLine(
        String id, {
        double? total,
        String estimate = 'estimate-1',
      }) => jsonEncode({
        'id': id,
        'estimate_id': estimate,
        'item_total_cost': total,
      });

      void seedRefusal(
        String id, {
        double? total,
        String estimate = 'estimate-1',
      }) => database.seedRefusal({
        'id': id,
        'estimate_id': estimate,
        'line': refusedLine(id, total: total, estimate: estimate),
        'reason': '42501',
        'refused_at': '2026-11-18T09:30:00.000Z',
      });

      test(
        'counts a refused line that only its refusal record holds',
        () async {
          seedServer({'server-1': 2000});
          seedRefusal('refused-1', total: 40);

          final result = await repository.getEstimateItemsTotal('estimate-1');

          expect(result.getRightOrNull(), 2040);
        },
      );

      test('counts a refused line once, with the phone\'s total, while its row '
          'is still on the phone', () async {
        await repository.addCostItemOnPhone(line());
        seedRefusal('line-1', total: 80);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 100);
      });

      test('counts the refused version of a line instead of the older version '
          'on the server', () async {
        seedServer({'line-1': 50});
        seedRefusal('line-1', total: 80);

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 80);
      });

      test('counts a refused line that had no total as 0', () async {
        seedServer({'server-1': 2000});
        seedRefusal('refused-1');

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 2000);
      });

      test('does not count another estimate\'s refused line', () async {
        seedRefusal('refused-1', total: 40, estimate: 'estimate-2');

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 0);
      });

      test('fails when the refusal records cannot be read', () async {
        database.refusalReadError = StateError('database locked');

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(
          result.getLeftOrNull(),
          const EstimationFailure(
            errorType: EstimationErrorType.unexpectedDatabaseError,
          ),
        );
      });

      test('does not count another estimate\'s lines on the phone', () async {
        await repository.addCostItemOnPhone(line());
        await repository.addCostItemOnPhone(
          MaterialCostItem(
            id: 'other',
            estimateId: 'estimate-2',
            itemName: 'Sand',
            calculation: const {},
            itemTotalCost: 50,
            createdAt: DateTime.utc(2026, 11, 14),
            updatedAt: DateTime.utc(2026, 11, 14),
            currency: 'USD',
            unitPrice: const Money(amount: 5),
            quantity: const Quantity(value: 10, unit: Unit.bags),
            rateStatus: RateStatus.ownRateUnconfirmed,
            quantityProvenance: QuantityProvenance.manual,
          ),
        );

        final result = await repository.getEstimateItemsTotal('estimate-1');

        expect(result.getRightOrNull(), 100);
      });

      test('fails when the phone cannot be read', () async {
        database.getAllError = StateError('database locked');

        final result = await repository.getEstimateItemsTotal('estimate-1');

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
