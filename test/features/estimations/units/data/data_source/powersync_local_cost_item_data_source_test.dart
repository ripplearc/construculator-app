import 'dart:convert';

import 'package:construculator/features/estimation/data/data_source/interfaces/local_cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/powersync_local_cost_item_data_source.dart';
import 'package:construculator/features/estimation/data/models/cost_item_dto.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_cost_items_database.dart';

void main() {
  group('PowerSyncLocalCostItemDataSource', () {
    late FakeCostItemsDatabase database;
    late LocalCostItemDataSource dataSource;

    CostItemDto line({
      String id = 'line-1',
      String estimateId = 'estimate-1',
      String itemName = 'Plywood',
      String createdAt = '2026-11-14T10:00:00.000Z',
    }) => CostItemDto(
      id: id,
      estimateId: estimateId,
      itemName: itemName,
      itemType: 'material',
      calculation: const {'unit_price': 10.5, 'quantity': 2.0},
      itemTotalCost: 21,
      createdAt: createdAt,
      updatedAt: createdAt,
      currency: 'USD',
      unitPrice: 10.5,
      quantity: 2,
      unitMeasurement: 'pieces',
      rateStatus: 'own_rate_unconfirmed',
      quantityProvenance: 'manual',
    );

    setUp(() {
      database = FakeCostItemsDatabase();
      Modular.init(_DataSourceTestModule(database));
      dataSource = Modular.get<LocalCostItemDataSource>();
    });

    tearDown(Modular.destroy);

    group('saveCostItemOnPhone', () {
      test('keeps the line under the id it was given', () async {
        await dataSource.saveCostItemOnPhone(line(id: 'line-7'));

        expect(database.rows.single['id'], 'line-7');
      });

      test('stores the calculation as JSON text', () async {
        await dataSource.saveCostItemOnPhone(line());

        expect(
          database.rows.single['calculation'],
          '{"unit_price":10.5,"quantity":2.0}',
        );
      });

      test('leaves one row when the same line is saved twice', () async {
        await dataSource.saveCostItemOnPhone(line());
        await dataSource.saveCostItemOnPhone(line());

        expect(database.rows, hasLength(1));
      });

      test('keeps the later save when the same id is saved twice', () async {
        await dataSource.saveCostItemOnPhone(line(itemName: 'Plywood'));
        await dataSource.saveCostItemOnPhone(line(itemName: 'Plywood 3/4 in'));

        expect(database.rows.single['item_name'], 'Plywood 3/4 in');
      });

      test('rethrows when the phone cannot write', () async {
        database.executeError = StateError('disk full');

        await expectLater(
          dataSource.saveCostItemOnPhone(line()),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('loadCostItemsByEstimateId', () {
      test('returns a saved line with every value it was saved with', () async {
        await dataSource.saveCostItemOnPhone(line());

        final lines = await dataSource.loadCostItemsByEstimateId('estimate-1');

        expect(lines, [line()]);
      });

      test('returns only the lines of the asked estimate', () async {
        await dataSource.saveCostItemOnPhone(line(id: 'mine'));
        await dataSource.saveCostItemOnPhone(
          line(id: 'theirs', estimateId: 'estimate-2'),
        );

        final lines = await dataSource.loadCostItemsByEstimateId('estimate-1');

        expect(lines.map((l) => l.id), ['mine']);
      });

      test('returns the oldest line first', () async {
        await dataSource.saveCostItemOnPhone(
          line(id: 'newer', createdAt: '2026-11-14T12:00:00.000Z'),
        );
        await dataSource.saveCostItemOnPhone(
          line(id: 'older', createdAt: '2026-11-14T09:00:00.000Z'),
        );

        final lines = await dataSource.loadCostItemsByEstimateId('estimate-1');

        expect(lines.map((l) => l.id), ['older', 'newer']);
      });

      test('orders lines with the same time by id', () async {
        await dataSource.saveCostItemOnPhone(line(id: 'b'));
        await dataSource.saveCostItemOnPhone(line(id: 'a'));

        final lines = await dataSource.loadCostItemsByEstimateId('estimate-1');

        expect(lines.map((l) => l.id), ['a', 'b']);
      });

      test('returns no lines for an estimate with none', () async {
        expect(
          await dataSource.loadCostItemsByEstimateId('estimate-9'),
          isEmpty,
        );
      });

      test('rethrows when the phone cannot read', () async {
        database.getAllError = StateError('database locked');

        await expectLater(
          dataSource.loadCostItemsByEstimateId('estimate-1'),
          throwsA(isA<StateError>()),
        );
      });
    });
    group('loadRefusedLineTotalsByEstimateId', () {
      void seedRefusal(
        String id, {
        String estimateId = 'estimate-1',
        Map<String, Object?> line = const {'item_total_cost': 21.5},
      }) => database.seedRefusal({
        'id': id,
        'estimate_id': estimateId,
        'line': jsonEncode({'id': id, 'estimate_id': estimateId, ...line}),
        'reason': '42501',
        'refused_at': '2026-11-18T09:30:00.000Z',
      });

      test('returns the saved total of each refused line by its id', () async {
        seedRefusal('line-1');
        seedRefusal('line-2', line: {'item_total_cost': 40});

        final totals = await dataSource.loadRefusedLineTotalsByEstimateId(
          'estimate-1',
        );

        expect(totals, {'line-1': 21.5, 'line-2': 40.0});
      });

      test('returns 0 for a refused line that had no total', () async {
        seedRefusal('line-1', line: const {});

        final totals = await dataSource.loadRefusedLineTotalsByEstimateId(
          'estimate-1',
        );

        expect(totals, {'line-1': 0.0});
      });

      test('returns only the refused lines of the asked estimate', () async {
        seedRefusal('line-1');
        seedRefusal('other', estimateId: 'estimate-2');

        final totals = await dataSource.loadRefusedLineTotalsByEstimateId(
          'estimate-1',
        );

        expect(totals.keys, ['line-1']);
      });

      test('returns nothing for an estimate with no refused line', () async {
        final totals = await dataSource.loadRefusedLineTotalsByEstimateId(
          'estimate-1',
        );

        expect(totals, isEmpty);
      });

      test('rethrows when the phone cannot read', () async {
        database.refusalReadError = StateError('database locked');

        await expectLater(
          dataSource.loadRefusedLineTotalsByEstimateId('estimate-1'),
          throwsA(isA<StateError>()),
        );
      });
    });

    group('watchCostItemIdsWithPendingUpload', () {
      test(
        'lists a line saved on the phone that is waiting to upload',
        () async {
          await dataSource.saveCostItemOnPhone(line(id: 'line-1'));

          await expectLater(
            dataSource.watchCostItemIdsWithPendingUpload('estimate-1'),
            emits({'line-1'}),
          );
        },
      );

      test('leaves out a line the server delivered', () async {
        database.seedRow({...line().toJson(), 'calculation': '{}'});

        await expectLater(
          dataSource.watchCostItemIdsWithPendingUpload('estimate-1'),
          emits(<String>{}),
        );
      });

      test('drops a line once its upload finishes', () async {
        await dataSource.saveCostItemOnPhone(line(id: 'line-1'));

        final seen = expectLater(
          dataSource.watchCostItemIdsWithPendingUpload('estimate-1'),
          emitsInOrder([
            {'line-1'},
            <String>{},
          ]),
        );
        database.finishUpload('line-1');

        await seen;
      });

      test('adds a line saved while watching', () async {
        await dataSource.saveCostItemOnPhone(line(id: 'line-1'));

        final seen = expectLater(
          dataSource.watchCostItemIdsWithPendingUpload('estimate-1'),
          emitsInOrder([
            {'line-1'},
            {'line-1', 'line-2'},
          ]),
        );
        await dataSource.saveCostItemOnPhone(line(id: 'line-2'));

        await seen;
      });

      test('leaves other estimates\' lines out and stays quiet when only '
          'they change', () async {
        final seen = expectLater(
          dataSource.watchCostItemIdsWithPendingUpload('estimate-1').take(2),
          emitsInOrder([
            <String>{},
            {'line-1'},
            emitsDone,
          ]),
        );
        await dataSource.saveCostItemOnPhone(
          line(id: 'theirs', estimateId: 'estimate-2'),
        );
        await dataSource.saveCostItemOnPhone(line(id: 'line-1'));

        await seen;
      });

      test('passes on a failed read of the phone', () async {
        final seen = expectLater(
          dataSource.watchCostItemIdsWithPendingUpload('estimate-1'),
          emitsInOrder([<String>{}, emitsError(isA<StateError>())]),
        );
        database.failWatches(StateError('database locked'));

        await seen;
      });
    });
  });
}

class _DataSourceTestModule extends Module {
  final FakeCostItemsDatabase database;

  _DataSourceTestModule(this.database);

  @override
  void binds(Injector i) {
    i.addSingleton<LocalCostItemDataSource>(
      () => PowerSyncLocalCostItemDataSource(database: database),
    );
  }
}
