import 'dart:async';

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
    // Explicit dispose is required, not redundant: Modular.dispose<T>() maps to
    // auto_injector's disposeSingleton<T>(), which drops the instance without
    // invoking Disposable.dispose(). Only module teardown calls that. Without
    // this line the previous test's manager keeps its auth subscription and
    // keeps driving the shared fake database.
    (Modular.get<PowerSyncManager>() as Disposable).dispose();
    Modular.dispose<PowerSyncManager>();
    fakeSupabase.reset();
    fakeDatabase.reset();
  });

  PowerSyncManager startManager() => Modular.get<PowerSyncManager>();

  /// Awaits every lifecycle operation queued so far. The auth listener starts
  /// them with [unawaited], so there is no future for the test to hold; this
  /// is a deterministic settle point that never drains the real event loop.
  Future<void> settle() async {
    await (Modular.get<PowerSyncManager>() as PowerSyncManagerImpl)
        .pendingOperations;
  }

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

  group('PowerSyncManager', () {
    test('exposes the database opened during bootstrap', () {
      final manager = startManager();

      expect(manager.database, same(fakeDatabase));
    });

    test('does not connect when no session exists at startup', () async {
      startManager();
      await settle();

      expect(fakeDatabase.connectCallCount, 0);
    });

    test(
      'connects immediately when already authenticated at startup',
      () async {
        signIn();

        startManager();
        await settle();

        expect(fakeDatabase.connectCallCount, 1);
        expect(fakeDatabase.lastConnector, same(moduleConnector()));
      },
    );

    test('connects when a sign-in event is emitted', () async {
      startManager();

      signIn();
      await settle();

      expect(fakeDatabase.connectCallCount, 1);
      expect(fakeDatabase.lastConnector, same(moduleConnector()));
    });

    test('disconnects and clears when a sign-out event is emitted', () async {
      signIn();
      startManager();

      fakeSupabase.setCurrentUser(null);
      await settle();

      expect(fakeDatabase.disconnectAndClearCallCount, 1);
    });

    test('does not establish duplicate connections', () async {
      startManager();

      signIn();

      signIn();
      await settle();

      expect(fakeDatabase.connectCallCount, 1);
    });

    test('reconnects after a sign-out followed by a new sign-in', () async {
      signIn();
      final manager = startManager();
      await settle();
      expect(fakeDatabase.connectCallCount, 1);

      fakeSupabase.setCurrentUser(null);
      signIn();
      await settle();

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

    test(
      'disconnectAndClear failure keeps the manager connected for a retry',
      () async {
        signIn();
        final manager = startManager();
        await settle();
        fakeDatabase.disconnectAndClearError = Exception('disk error');

        await manager.disconnectAndClear();
        expect(fakeDatabase.disconnectAndClearCallCount, 1);

        fakeDatabase.disconnectAndClearError = null;
        await manager.disconnectAndClear();
        expect(fakeDatabase.disconnectAndClearCallCount, 2);
      },
    );

    test('disconnectAndClear is a no-op when not connected', () async {
      final manager = startManager();
      await settle();

      await manager.disconnectAndClear();

      expect(fakeDatabase.disconnectAndClearCallCount, 0);
    });

    test('stops reacting to auth events after dispose', () async {
      final manager = startManager();

      (manager as Disposable).dispose();
      signIn();
      await settle();

      expect(fakeDatabase.connectCallCount, 0);
    });

    test('retries a failed clear before connecting the next user', () async {
      signIn();
      startManager();
      await settle();
      expect(fakeDatabase.connectCallCount, 1);

      fakeDatabase.disconnectAndClearError = Exception('disk error');
      fakeSupabase.setCurrentUser(null);
      await settle();
      expect(fakeDatabase.disconnectAndClearCallCount, 1);

      fakeDatabase.disconnectAndClearError = null;
      signIn();
      await settle();

      expect(fakeDatabase.disconnectAndClearCallCount, 2);
      expect(
        fakeDatabase.connectCallCount,
        2,
        reason: 'user B must establish its own sync connection',
      );
    });

    test(
      'refuses to connect while the previous session is still uncleared',
      () async {
        signIn();
        startManager();
        await settle();

        fakeDatabase.disconnectAndClearError = Exception('disk error');
        fakeSupabase.setCurrentUser(null);
        await settle();

        // The clear is still failing when the next user signs in.
        signIn();
        await settle();

        expect(fakeDatabase.disconnectAndClearCallCount, 2);
        expect(
          fakeDatabase.connectCallCount,
          1,
          reason: 'must not sync a new user on top of the previous rows',
        );
      },
    );

    test(
      'serializes a sign-out arriving during an in-flight connect',
      () async {
        startManager();
        final gate = Completer<void>();
        fakeDatabase.connectGate = gate.future;

        signIn();
        fakeSupabase.setCurrentUser(null);

        gate.complete();
        fakeDatabase.connectGate = null;
        await settle();

        expect(fakeDatabase.completedOperations, [
          'connect',
          'disconnectAndClear',
        ]);

        signIn();
        await settle();

        expect(fakeDatabase.connectCallCount, 2);
      },
    );
  });
}

// Minimal host module that mirrors how the real `AppModule` composes
// [PowerSyncModule], so the production module's wiring — including the eager
// [PowerSyncManager] singleton — is exercised directly. [PowerSyncModule]
// exposes its binds via `exportedBinds`, which are only resolvable through an
// importing module, hence this wrapper.
class _PowerSyncTestModule extends Module {
  final AppBootstrap appBootstrap;
  _PowerSyncTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [PowerSyncModule(appBootstrap)];
}
