import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
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

    YourRateEntryDto newRate() => const YourRateEntryDto(
      id: '',
      companyId: 'company-1',
      category: 'equipment',
      itemName: 'Excavator',
      rateAmount: 250,
      rateCurrency: 'USD',
      equipmentMethod: 'day',
      savedAt: '2026-10-01T08:00:00.000Z',
    );

    // PowerSync queues a write as a PUT whose data holds the columns but not
    // the id, which travels as its own field.
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
