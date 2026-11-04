import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/interfaces/your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rate_refusal_data_source.dart';
import 'package:construculator/features/estimation/data/data_source/local_your_rates_data_source.dart';
import 'package:construculator/features/estimation/data/models/your_rate_entry_dto.dart';
import 'package:construculator/features/estimation/data/repositories/your_rates_repository_impl.dart';
import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../../utils/fake_app_bootstrap_factory.dart';
import '../../../../utils/fake_phone_backed_power_sync_database.dart';
import '../../../../utils/fake_your_rates_database.dart';

void main() {
  group('a default the server refused, from upload to the Your rates list', () {
    late FakeYourRatesDatabase phone;
    late FakeSupabaseWrapper server;
    late YourRatesDataSource dataSource;
    late YourRatesRepositoryImpl repository;
    late PowerSyncBackendConnector connector;

    // One Modular.init for the file, as in your_rates_upload_test.dart.
    setUpAll(() {
      phone = FakeYourRatesDatabase();
      final bootstrap = FakeAppBootstrapFactory.create();
      server = bootstrap.supabaseWrapper as FakeSupabaseWrapper;
      Modular.init(_FlowTestModule(bootstrap, phone));
      dataSource = Modular.get<YourRatesDataSource>();
      repository =
          Modular.get<YourRatesRepository>() as YourRatesRepositoryImpl;
      connector = Modular.get<PowerSyncBackendConnector>();
    });

    tearDownAll(Modular.destroy);

    setUp(() {
      server.reset();
      server.setCurrentUser(
        FakeUser(id: 'user-1', createdAt: '2026-10-01T08:00:00.000Z'),
      );
      phone.reset();
    });

    YourRateEntryDto excavator(double rateAmount) => YourRateEntryDto(
      id: '',
      companyId: 'company-1',
      category: 'equipment',
      itemName: 'Excavator',
      rateAmount: rateAmount,
      rateCurrency: 'USD',
      equipmentMethod: 'day',
      savedAt: '2026-10-01T08:00:00.000Z',
    );

    test(
      'a refused new price shows the price the server holds, under another id',
      () async {
        server.addTableData('your_rates', [
          {
            'id': 'server-row',
            'company_id': 'company-1',
            'category': 'equipment',
            'item_name': 'Excavator',
            'equipment_method': 'day',
            'rate_amount': 400.0,
          },
        ]);
        await dataSource.insertRate(excavator(450));
        server.shouldThrowOnUpsert = true;
        server.upsertExceptionType = SupabaseExceptionType.postgrest;
        server.postgrestErrorCode = PostgresErrorCode.checkViolation;
        final stored = Map.of(phone.insertedRows.single);
        final columns = Map.of(stored)..remove('id');
        final database = FakePhoneBackedPowerSyncDatabase(phone)
          ..setNextTransaction(
            FakeCrudTransaction([
              CrudEntry(
                1,
                UpdateType.put,
                'your_rates',
                stored['id']! as String,
                null,
                columns,
              ),
            ]),
          );

        await connector.uploadData(database);

        final found = await repository.search(
          '',
          category: CostItemType.equipment,
          companyId: 'company-1',
        );
        expect(found.getRightOrNull()!.single.rate.amount, 400.0);
      },
    );
  });
}

class _FlowTestModule extends Module {
  final AppBootstrap bootstrap;
  final FakeYourRatesDatabase phone;

  _FlowTestModule(this.bootstrap, this.phone);

  @override
  List<Module> get imports => [
    AuthLibraryModule(bootstrap),
    PowerSyncModule(bootstrap),
  ];

  @override
  void binds(Injector i) {
    i
      ..addSingleton<YourRatesDataSource>(
        () => LocalYourRatesDataSource(database: phone, clock: FakeClockImpl()),
      )
      ..addSingleton<YourRateRefusalDataSource>(
        () => LocalYourRateRefusalDataSource(
          database: phone,
          clock: FakeClockImpl(),
        ),
      )
      ..addSingleton<YourRatesRepository>(
        () => YourRatesRepositoryImpl(
          dataSource: i.get(),
          refusalDataSource: i.get(),
          authRepository: i.get(),
        ),
      );
  }
}
