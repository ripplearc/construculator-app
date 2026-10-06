import 'dart:async';

import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../utils/fake_your_rates_database.dart';

void main() {
  group('LocalYourRatesDataSource', () {
    late FakeYourRatesDatabase database;
    late FakeClockImpl clock;
    late YourRatesDataSource dataSource;

    Map<String, Object?> row({
      required String id,
      String companyId = 'company-1',
      String category = 'equipment',
      String itemName = 'Excavator',
      String savedAt = '2026-09-23T12:00:00.000Z',
    }) => {
      'id': id,
      'company_id': companyId,
      'category': category,
      'item_name': itemName,
      'rate_amount': 250.0,
      'rate_currency': 'USD',
      'unit': null,
      'equipment_method': 'day',
      'entry_label': null,
      'saved_at': savedAt,
      'created_at': savedAt,
      'updated_at': savedAt,
    };

    YourRateEntryDto newDto({
      String companyId = 'company-1',
      String category = 'equipment',
      String itemName = 'Excavator',
      double rateAmount = 250.0,
      String? entryLabel,
    }) => YourRateEntryDto(
      id: '',
      companyId: companyId,
      category: category,
      itemName: itemName,
      rateAmount: rateAmount,
      rateCurrency: 'USD',
      equipmentMethod: 'day',
      entryLabel: entryLabel,
      savedAt: '2026-10-01T08:00:00.000Z',
    );

    setUp(() {
      database = FakeYourRatesDatabase();
      clock = FakeClockImpl();
      Modular.init(_DataSourceTestModule(database, clock));
      dataSource = Modular.get<YourRatesDataSource>();
    });

    tearDown(Modular.destroy);

    group('loadRates', () {
      test(
        'returns the rows that sync delivered, with no network call',
        () async {
          database.seedRow(row(id: 'a'));

          final rates = await dataSource.loadRates();

          expect(rates.map((rate) => rate.id), ['a']);
        },
      );

      test(
        'keeps one company\'s rows out of another company\'s read',
        () async {
          database.seedRow(row(id: 'mine'));
          database.seedRow(row(id: 'theirs', companyId: 'company-2'));

          final rates = await dataSource.loadRates(companyId: 'company-1');

          expect(rates.map((rate) => rate.id), ['mine']);
        },
      );

      test('returns only the asked category', () async {
        database.seedRow(row(id: 'equipment-row'));
        database.seedRow(row(id: 'labor-row', category: 'labor'));

        final rates = await dataSource.loadRates(category: 'labor');

        expect(rates.map((rate) => rate.id), ['labor-row']);
      });

      test('orders most recently saved first', () async {
        database.seedRow(row(id: 'older', savedAt: '2026-09-01T00:00:00.000Z'));
        database.seedRow(row(id: 'newer', savedAt: '2026-09-02T00:00:00.000Z'));

        final rates = await dataSource.loadRates();

        expect(rates.map((rate) => rate.id), ['newer', 'older']);
      });

      test(
        'orders a synced timestamp and a locally written one by time',
        () async {
          database.seedRow(
            row(id: 'synced', savedAt: '2026-09-02 00:00:00+00'),
          );
          database.seedRow(
            row(id: 'local', savedAt: '2026-09-02T09:00:00.000Z'),
          );

          final rates = await dataSource.loadRates();

          expect(rates.map((rate) => rate.id), ['local', 'synced']);
        },
      );

      test('caps the result at the limit after ordering', () async {
        database.seedRow(
          row(id: 'oldest', savedAt: '2026-09-01T00:00:00.000Z'),
        );
        database.seedRow(
          row(id: 'middle', savedAt: '2026-09-02T00:00:00.000Z'),
        );
        database.seedRow(
          row(id: 'newest', savedAt: '2026-09-03T00:00:00.000Z'),
        );

        final rates = await dataSource.loadRates(limit: 2);

        expect(rates.map((rate) => rate.id), ['newest', 'middle']);
      });

      test('reports a read the phone cannot do', () async {
        database.getAllError = StateError('database locked');

        await expectLater(dataSource.loadRates(), throwsStateError);
      });
    });

    group('insertRate', () {
      test('gives the new row an id and shows it in the next read', () async {
        final saved = await dataSource.insertRate(newDto());

        final rates = await dataSource.loadRates();
        expect(saved.id, isNotEmpty);
        expect(rates.map((rate) => rate.id), [saved.id]);
      });

      test('stamps created and updated time from the clock', () async {
        clock.advance(const Duration(hours: 1));

        final saved = await dataSource.insertRate(newDto());

        final expected = clock.now().toUtc().toIso8601String();
        expect(saved.createdAt, expected);
        expect(saved.updatedAt, expected);
      });

      test('keeps every saved value', () async {
        final saved = await dataSource.insertRate(
          newDto(itemName: 'Skid steer', rateAmount: 310, entryLabel: '20 ton'),
        );

        expect(saved.itemName, 'Skid steer');
        expect(saved.rateAmount, 310);
        expect(saved.entryLabel, '20 ton');
        expect(saved.equipmentMethod, 'day');
      });

      test('reports a write the phone cannot do', () async {
        database.executeError = StateError('disk full');

        await expectLater(dataSource.insertRate(newDto()), throwsStateError);
      });
    });

    group('updateRate', () {
      test('replaces the price on the row with that id', () async {
        final saved = await dataSource.insertRate(newDto());

        await dataSource.updateRate(saved.id, newDto(rateAmount: 400));

        final rates = await dataSource.loadRates();
        expect(rates.single.rateAmount, 400);
      });

      test(
        'moves updated time forward and leaves created time alone',
        () async {
          final saved = await dataSource.insertRate(newDto());
          clock.advance(const Duration(hours: 2));

          final updated = await dataSource.updateRate(saved.id, newDto());

          expect(updated.createdAt, saved.createdAt);
          expect(updated.updatedAt, isNot(saved.updatedAt));
        },
      );

      test('reports a row that is not on the phone', () async {
        await expectLater(
          dataSource.updateRate('missing', newDto()),
          throwsStateError,
        );
      });
    });

    group('sync stream', () {
      test('is activated once however many reads and writes follow', () async {
        await dataSource.loadRates();
        await dataSource.insertRate(newDto());
        await dataSource.loadRates();

        expect(database.syncStreamCalls, ['user_rates']);
      });

      test('is waited on for its first rows before the first read', () async {
        database.firstSyncGate = Completer();

        final read = dataSource.loadRates();
        await pumpEventQueue();
        expect(database.getAllCalls, isEmpty);

        database.firstSyncGate!.complete();
        await read;

        expect(database.getAllCalls, hasLength(1));
      });

      test('is not waited on for ever when it cannot sync', () {
        fakeAsync((async) {
          database.firstSyncGate = Completer();
          var finished = false;
          dataSource.loadRates().then((_) => finished = true);

          async.elapse(const Duration(seconds: 2));
          expect(finished, isFalse);

          async.elapse(const Duration(seconds: 2));
          expect(finished, isTrue);
        });
      });

      test('is released when the data source is disposed', () async {
        await dataSource.loadRates();

        await (dataSource as LocalYourRatesDataSource).dispose();

        expect(database.syncStreamUnsubscribes, ['user_rates']);
      });

      test('is retried on the next call after activating it failed', () async {
        database.syncStreamError = StateError('not ready');
        await expectLater(dataSource.loadRates(), throwsStateError);
        database.syncStreamError = null;

        final rates = await dataSource.loadRates();

        expect(rates, isEmpty);
        expect(database.syncStreamCalls, ['user_rates', 'user_rates']);
      });
    });
  });
}

class _DataSourceTestModule extends Module {
  final FakeYourRatesDatabase database;
  final FakeClockImpl clock;

  _DataSourceTestModule(this.database, this.clock);

  @override
  void binds(Injector i) {
    i.addSingleton<YourRatesDataSource>(
      () => LocalYourRatesDataSource(database: database, clock: clock),
    );
  }
}
