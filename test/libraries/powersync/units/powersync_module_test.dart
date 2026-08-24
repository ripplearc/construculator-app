import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/powersync_manager_impl.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

// Lives in its own file because it must observe the module immediately after
// commit, before anything resolves [PowerSyncManager]. The manager test's
// shared setUp resolves it on every test, which would mask the difference
// between an eager and a lazy singleton.
void main() {
  // A single module graph for the whole file: flutter_modular keeps bind
  // registrations alive across destroy()/init() within one process, so
  // re-initialising per test resolves stale instances from the previous one.
  final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final fakeDatabase = FakePowerSyncDatabase();

  setUpAll(
    () => Modular.init(
      _PowerSyncTestModule(
        FakeAppBootstrapFactory.create(
          supabaseWrapper: fakeSupabase,
          powerSyncDatabase: fakeDatabase,
        ),
      ),
    ),
  );

  tearDownAll(() {
    Modular.destroy();
    fakeSupabase.dispose();
  });

  void signIn() {
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'user-1',
        email: 'user@example.com',
        createdAt: '2000-01-01T00:00:00.000Z',
      ),
    );
  }

  group('PowerSyncModule', () {
    test('manager listens to auth events without being resolved', () async {
      // Deliberately no Modular.get before the events: the eager singleton is
      // already subscribed at module commit. Signing out afterwards means a
      // lazy singleton constructed by the settle() lookup below would see
      // isAuthenticated == false and never connect, leaving the count at 0.
      signIn();
      fakeSupabase.setCurrentUser(null);

      await (Modular.get<PowerSyncManager>() as PowerSyncManagerImpl)
          .pendingOperations;

      expect(
        fakeDatabase.connectCallCount,
        1,
        reason: 'the manager must be eager, not resolved on first use',
      );
      expect(fakeDatabase.disconnectAndClearCallCount, 1);
    });

    test('injects the bootstrap database and the module connector', () {
      final manager = Modular.get<PowerSyncManager>();

      expect(manager.database, same(fakeDatabase));
      expect(Modular.get<PowerSyncDatabase>(), same(fakeDatabase));
    });
  });
}

// Minimal host module that mirrors how the real `AppModule` composes
// [PowerSyncModule]. [PowerSyncModule] exposes its binds via `exportedBinds`,
// which are only resolvable through an importing module, hence this wrapper.
class _PowerSyncTestModule extends Module {
  final AppBootstrap appBootstrap;
  _PowerSyncTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}
