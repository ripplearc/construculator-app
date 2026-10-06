import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_phone_backed_power_sync_database.dart';
import '../../../../utils/fake_your_rates_database.dart';

void main() {
  group('a Your rates price saved with no signal', () {
    late FakeYourRatesDatabase phone;
    late FakeSupabaseWrapper server;
    late YourRatesDataSource dataSource;
    late PowerSyncBackendConnector connector;

    // One Modular.init for the file: modular_core caches an imported module's
    // injector by runtimeType and keeps it across Modular.destroy, so a fresh
    // bootstrap per test would leave the connector on the first test's server.
    setUpAll(() {
      phone = FakeYourRatesDatabase();
      final bootstrap = FakeAppBootstrapFactory.create();
      server = bootstrap.supabaseWrapper as FakeSupabaseWrapper;
      Modular.init(_UploadTestModule(bootstrap, phone));
      dataSource = Modular.get<YourRatesDataSource>();
      connector = Modular.get<PowerSyncBackendConnector>();
    });

    tearDownAll(Modular.destroy);

    setUp(() {
      server.reset();
      phone.reset();
    });

    YourRateEntryDto newRate({double rateAmount = 250}) => YourRateEntryDto(
      id: '',
      companyId: 'company-1',
      category: 'equipment',
      itemName: 'Excavator',
      rateAmount: rateAmount,
      rateCurrency: 'USD',
      equipmentMethod: 'day',
      savedAt: '2026-10-01T08:00:00.000Z',
    );

    CrudEntry queuedPutFor(Map<String, Object?> storedRow) {
      final columns = Map.of(storedRow)..remove('id');
      return CrudEntry(
        1,
        UpdateType.put,
        'your_rates',
        storedRow['id']! as String,
        null,
        columns,
      );
    }

    test('is uploaded under the id the phone gave it', () async {
      final saved = await dataSource.insertRate(newRate());
      final fakeDatabase = FakePowerSyncDatabase()
        ..setNextTransaction(
          FakeCrudTransaction([queuedPutFor(phone.insertedRows.single)]),
        );

      await connector.uploadData(fakeDatabase);

      final upload = server.getMethodCallsFor('upsert').single;
      expect(upload['table'], 'your_rates');
      expect(upload['data'], containsPair('id', saved.id));
      expect(upload['data'], containsPair('item_name', 'Excavator'));
      expect(upload['data'], containsPair('rate_amount', 250.0));
    });

    test('is edited on the server under that same id', () async {
      final saved = await dataSource.insertRate(newRate());
      server.addTableData('your_rates', [
        {'id': saved.id, 'rate_amount': 250.0},
      ]);
      final fakeDatabase = FakePowerSyncDatabase()
        ..setNextTransaction(
          FakeCrudTransaction([
            CrudEntry(2, UpdateType.patch, 'your_rates', saved.id, null, {
              'rate_amount': 400.0,
            }),
          ]),
        );

      await connector.uploadData(fakeDatabase);

      final update = server.getMethodCallsFor('update').single;
      expect(update['filterValue'], saved.id);
      expect(update['data'], containsPair('rate_amount', 400.0));
    });

    group('refused by the server', () {
      final excavatorKey = YourRateRefusalKey.of('Excavator', 'day');

      Future<FakeCrudTransaction> uploadRefusedAmountChange({
        required PostgresErrorCode code,
        double? acceptedOnServer,
        double refusedAmount = 450,
        Map<String, Object?>? changes,
      }) async {
        final saved = await dataSource.insertRate(newRate());
        await dataSource.updateRate(
          saved.id,
          newRate(rateAmount: refusedAmount),
        );
        if (acceptedOnServer != null) {
          server.addTableData('your_rates', [
            {'id': saved.id, 'rate_amount': acceptedOnServer},
          ]);
        }
        server.shouldThrowOnUpdate = true;
        server.updateExceptionType = SupabaseExceptionType.postgrest;
        server.postgrestErrorCode = code;
        final transaction = FakeCrudTransaction([
          CrudEntry(
            2,
            UpdateType.patch,
            'your_rates',
            saved.id,
            null,
            changes ?? {'rate_amount': refusedAmount},
          ),
        ]);
        final database = FakePhoneBackedPowerSyncDatabase(phone)
          ..setNextTransaction(transaction);
        await connector.uploadData(database);
        return transaction;
      }

      test(
        'keeps the refused and the last accepted price for the item',
        () async {
          final transaction = await uploadRefusedAmountChange(
            code: PostgresErrorCode.checkViolation,
            acceptedOnServer: 400,
          );

          final refusal = phone.refusalRow(excavatorKey)!;
          expect(refusal['refused_amount'], 450.0);
          expect(refusal['accepted_amount'], 400.0);
          expect(refusal['shown_at'], isNull);
          expect(transaction.isCompleted, isTrue);
        },
      );

      test('treats no access to the account as a refusal', () async {
        await uploadRefusedAmountChange(
          code: PostgresErrorCode.rlsViolation,
          acceptedOnServer: 400,
        );

        expect(phone.refusalRow(excavatorKey)!['refused_amount'], 450.0);
      });

      test(
        'keeps no accepted price when the server never accepted one',
        () async {
          await uploadRefusedAmountChange(
            code: PostgresErrorCode.checkViolation,
          );

          expect(phone.refusalRow(excavatorKey)!['accepted_amount'], isNull);
        },
      );

      test('keeps no accepted price when the server cannot be read', () async {
        server.shouldThrowOnSelectMatch = true;
        server.selectMatchExceptionType = SupabaseExceptionType.postgrest;

        await uploadRefusedAmountChange(
          code: PostgresErrorCode.rlsViolation,
          acceptedOnServer: 400,
        );

        expect(phone.refusalRow(excavatorKey)!['accepted_amount'], isNull);
      });

      test(
        'keeps the price the refused change carried, not a later local price',
        () async {
          final saved = await dataSource.insertRate(newRate());
          await dataSource.updateRate(saved.id, newRate(rateAmount: 460));
          server.shouldThrowOnUpdate = true;
          server.updateExceptionType = SupabaseExceptionType.postgrest;
          server.postgrestErrorCode = PostgresErrorCode.checkViolation;
          final database = FakePhoneBackedPowerSyncDatabase(phone)
            ..setNextTransaction(
              FakeCrudTransaction([
                CrudEntry(2, UpdateType.patch, 'your_rates', saved.id, null, {
                  'rate_amount': 450.0,
                }),
              ]),
            );

          await connector.uploadData(database);

          expect(phone.refusalRow(excavatorKey)!['refused_amount'], 450.0);
        },
      );

      test(
        'keeps the accepted price of the refused row, not of another',
        () async {
          final saved = await dataSource.insertRate(newRate());
          await dataSource.updateRate(saved.id, newRate(rateAmount: 450));
          server.addTableData('your_rates', [
            {'id': 'another-row', 'rate_amount': 111.0},
            {'id': saved.id, 'rate_amount': 400.0},
          ]);
          server.shouldThrowOnUpdate = true;
          server.updateExceptionType = SupabaseExceptionType.postgrest;
          server.postgrestErrorCode = PostgresErrorCode.checkViolation;
          final database = FakePhoneBackedPowerSyncDatabase(phone)
            ..setNextTransaction(
              FakeCrudTransaction([
                CrudEntry(2, UpdateType.patch, 'your_rates', saved.id, null, {
                  'rate_amount': 450.0,
                }),
              ]),
            );

          await connector.uploadData(database);

          expect(phone.refusalRow(excavatorKey)!['accepted_amount'], 400.0);
        },
      );

      test('forgets that the earlier refusal was shown', () async {
        phone.seedRefusal({
          'id': excavatorKey,
          'item_name': 'Excavator',
          'equipment_method': 'day',
          'refused_amount': 300.0,
          'accepted_amount': 400.0,
          'shown_at': '2026-10-06T12:00:00.000Z',
        });

        await uploadRefusedAmountChange(
          code: PostgresErrorCode.checkViolation,
          acceptedOnServer: 400,
        );

        final refusal = phone.refusalRow(excavatorKey)!;
        expect(refusal['refused_amount'], 450.0);
        expect(refusal['shown_at'], isNull);
      });

      test(
        'does not record a refused change that leaves the price alone',
        () async {
          final transaction = await uploadRefusedAmountChange(
            code: PostgresErrorCode.checkViolation,
            changes: {'entry_label': '35 ton'},
          );

          expect(phone.refusalRow(excavatorKey), isNull);
          expect(transaction.isCompleted, isTrue);
        },
      );

      test(
        'still unblocks the queue when the refusal cannot be recorded',
        () async {
          final saved = await dataSource.insertRate(newRate());
          server.shouldThrowOnUpdate = true;
          server.updateExceptionType = SupabaseExceptionType.postgrest;
          server.postgrestErrorCode = PostgresErrorCode.checkViolation;
          final transaction = FakeCrudTransaction([
            CrudEntry(2, UpdateType.patch, 'your_rates', saved.id, null, {
              'rate_amount': 450.0,
            }),
          ]);
          final database = FakePowerSyncDatabase()
            ..setNextTransaction(transaction);

          await connector.uploadData(database);

          expect(transaction.isCompleted, isTrue);
        },
      );
    });
  });
}

class _UploadTestModule extends Module {
  final AppBootstrap bootstrap;
  final FakeYourRatesDatabase phone;

  _UploadTestModule(this.bootstrap, this.phone);

  @override
  List<Module> get imports => [PowerSyncModule(bootstrap)];

  @override
  void binds(Injector i) {
    i.addSingleton<YourRatesDataSource>(
      () => LocalYourRatesDataSource(database: phone, clock: FakeClockImpl()),
    );
  }
}
