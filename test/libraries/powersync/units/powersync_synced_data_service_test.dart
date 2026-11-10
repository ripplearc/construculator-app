import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/powersync_manager_impl.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/powersync_synced_data_service.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

PowerSyncSyncedDataService buildService(PowerSyncManager manager) =>
    // ignore: no_direct_instantiation, reason: the service under test wraps the manager it is given
    PowerSyncSyncedDataService(manager: manager);

void main() {
  final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final fakeDatabase = FakePowerSyncDatabase();
  final bootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
    powerSyncDatabase: fakeDatabase,
  );

  setUpAll(() => Modular.init(_PowerSyncTestModule(bootstrap)));

  tearDownAll(() {
    Modular.destroy();
    fakeSupabase.dispose();
  });

  setUp(() {
    (Modular.get<PowerSyncManager>() as Disposable).dispose();
    Modular.dispose<PowerSyncManager>();
    fakeSupabase.reset();
    fakeDatabase.reset();
  });

  Future<void> settle() async {
    await (Modular.get<PowerSyncManager>() as PowerSyncManagerImpl)
        .pendingOperations;
  }

  void signIn() {
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'user-1',
        email: 'user@example.com',
        createdAt: '2000-01-01T00:00:00.000Z',
      ),
    );
  }

  group('PowerSyncSyncedDataService', () {
    test(
      'clears without touching local-only tables, even when not connected',
      () async {
        final service = buildService(Modular.get<PowerSyncManager>());
        await settle();

        await service.deleteSyncedDataAndUnsentEdits();

        expect(fakeDatabase.disconnectAndClearCallCount, 1);
        expect(fakeDatabase.lastClearLocal, isFalse);
      },
    );

    test('lets the manager connect again afterwards', () async {
      signIn();
      final manager = Modular.get<PowerSyncManager>();
      await settle();
      expect(fakeDatabase.connectCallCount, 1);

      await buildService(manager).deleteSyncedDataAndUnsentEdits();
      await manager.connect();

      expect(fakeDatabase.connectCallCount, 2);
    });

    test(
      'rethrows when the clear fails, and the next connect retries it',
      () async {
        signIn();
        final manager = Modular.get<PowerSyncManager>();
        await settle();
        fakeDatabase.disconnectAndClearError = Exception('disk error');

        await expectLater(
          buildService(manager).deleteSyncedDataAndUnsentEdits(),
          throwsException,
        );

        fakeDatabase.disconnectAndClearError = null;
        await manager.connect();

        expect(fakeDatabase.disconnectAndClearCallCount, 2);
        expect(fakeDatabase.connectCallCount, 2);
      },
    );
  });
}

class _PowerSyncTestModule extends Module {
  final AppBootstrap appBootstrap;
  _PowerSyncTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}
