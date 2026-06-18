import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/powersync/interfaces/powersync_manager.dart';
import 'package:construculator/libraries/powersync/powersync_module.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync/powersync.dart';

import '../../../utils/fake_app_bootstrap_factory.dart';

void main() {
  final fakeSupabase = FakeSupabaseWrapper(clock: FakeClockImpl());
  final fakeDatabase = FakePowerSyncDatabase();
  final bootstrap = FakeAppBootstrapFactory.create(
    supabaseWrapper: fakeSupabase,
    powerSyncDatabase: fakeDatabase,
  );

  setUpAll(() => Modular.init(_AppModule(bootstrap)));

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

  PowerSyncManager startManager() => Modular.get<PowerSyncManager>();

  PowerSyncBackendConnector moduleConnector() =>
      Modular.get<PowerSyncBackendConnector>();

  void signIn() {
    fakeSupabase.setCurrentUser(
      FakeUser(
        id: 'user-1',
        email: 'user@example.com',
        createdAt: '2000-01-01T00:00:00.000Z',
      ),
    );
  }

  /// Lets queued auth-stream events reach the manager's listener.
  ///
  /// The unit-test analogue of `tester.pumpAndSettle()`: there is no widget
  /// tree to pump here, so we drain the event queue to flush pending
  /// broadcast-stream deliveries instead. [pumpEventQueue] pumps repeatedly,
  /// so it settles multi-hop async chains a single timer tick would miss.
  Future<void> pumpAuthEvents() => pumpEventQueue();

  group('PowerSyncManager', () {
    test('exposes the database opened during bootstrap', () {
      final manager = startManager();

      expect(manager.database, same(fakeDatabase));
    });

    test('does not connect when no session exists at startup', () {
      startManager();

      expect(fakeDatabase.connectCallCount, 0);
    });

    test('connects immediately when already authenticated at startup', () {
      signIn();

      startManager();

      expect(fakeDatabase.connectCallCount, 1);
      expect(fakeDatabase.lastConnector, same(moduleConnector()));
    });

    test('connects when a sign-in event is emitted', () async {
      startManager();

      signIn();
      await pumpAuthEvents();

      expect(fakeDatabase.connectCallCount, 1);
      expect(fakeDatabase.lastConnector, same(moduleConnector()));
    });

    test('disconnects and clears when a sign-out event is emitted', () async {
      signIn();
      startManager();

      fakeSupabase.setCurrentUser(null);
      await pumpAuthEvents();

      expect(fakeDatabase.disconnectAndClearCallCount, 1);
    });

    test('does not establish duplicate connections', () async {
      startManager();

      signIn();
      await pumpAuthEvents();

      signIn();
      await pumpAuthEvents();

      expect(fakeDatabase.connectCallCount, 1);
    });

    test('reconnects after a sign-out followed by a new sign-in', () async {
      signIn();
      final manager = startManager();
      expect(fakeDatabase.connectCallCount, 1);

      fakeSupabase.setCurrentUser(null);
      await pumpAuthEvents();
      signIn();
      await pumpAuthEvents();

      expect(fakeDatabase.connectCallCount, 2);
      expect(fakeDatabase.disconnectAndClearCallCount, 1);
      expect(manager.database, same(fakeDatabase));
    });

    test('connect failure is swallowed and allows a later retry', () async {
      final manager = startManager();
      fakeDatabase.connectError = Exception('network down');

      await manager.connect();
      expect(fakeDatabase.connectCallCount, 1);

      fakeDatabase.connectError = null;
      await manager.connect();
      expect(fakeDatabase.connectCallCount, 2);
    });

    test('disconnectAndClear is a no-op when not connected', () async {
      final manager = startManager();

      await manager.disconnectAndClear();

      expect(fakeDatabase.disconnectAndClearCallCount, 0);
    });

    test('stops reacting to auth events after dispose', () async {
      final manager = startManager();

      (manager as Disposable).dispose();
      signIn();
      await pumpAuthEvents();

      expect(fakeDatabase.connectCallCount, 0);
    });
  });
}

// Minimal host module that mirrors how the real `AppModule` composes
// [PowerSyncModule], so the production module's wiring — including the eager
// [PowerSyncManager] singleton — is exercised directly. [PowerSyncModule]
// exposes its binds via `exportedBinds`, which are only resolvable through an
// importing module, hence this wrapper.
class _AppModule extends Module {
  final AppBootstrap appBootstrap;
  _AppModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}
