import 'dart:async';

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

  setUpAll(() => Modular.init(_PowerSyncTestModule(bootstrap)));

  tearDownAll(() {
    Modular.destroy();
    fakeSupabase.dispose();
  });

  setUp(() {
    // A new manager for every test, so no connection state carries over.
    Modular.dispose<PowerSyncManager>();
    fakeSupabase.reset();
    fakeDatabase.reset();
  });

  PowerSyncManager startManager() => Modular.get<PowerSyncManager>();

  PowerSyncBackendConnector moduleConnector() =>
      Modular.get<PowerSyncBackendConnector>();

  group('PowerSyncManager', () {
    test('exposes the database opened during bootstrap', () {
      final manager = startManager();

      expect(manager.database, same(fakeDatabase));
    });

    test(
      'does not connect or clear on its own, whatever the auth events',
      () async {
        final manager = startManager();
        fakeSupabase.setCurrentUser(
          FakeUser(
            id: 'user-1',
            email: 'user@example.com',
            createdAt: '2000-01-01T00:00:00.000Z',
          ),
        );
        fakeSupabase.setCurrentUser(null);

        await manager.disconnectKeepingData();

        expect(fakeDatabase.connectCallCount, 0);
        expect(fakeDatabase.disconnectAndClearCallCount, 0);
      },
    );

    test('connects with the module connector when asked', () async {
      final manager = startManager();

      await manager.connect();

      expect(fakeDatabase.connectCallCount, 1);
      expect(fakeDatabase.lastConnector, same(moduleConnector()));
    });

    test('does not establish duplicate connections', () async {
      final manager = startManager();

      await manager.connect();
      await manager.connect();

      expect(fakeDatabase.connectCallCount, 1);
    });

    test('disconnectAndClear keeps local-only tables', () async {
      final manager = startManager();
      await manager.connect();

      await manager.disconnectAndClear();

      expect(fakeDatabase.disconnectAndClearCallCount, 1);
      expect(fakeDatabase.lastClearLocal, isFalse);
    });

    test('reconnects after a clear', () async {
      final manager = startManager();
      await manager.connect();

      await manager.disconnectAndClear();
      await manager.connect();

      expect(fakeDatabase.connectCallCount, 2);
      expect(fakeDatabase.disconnectAndClearCallCount, 1);
      expect(manager.database, same(fakeDatabase));
    });

    group('disconnect', () {
      test('drops the connection and keeps the synced data', () async {
        final manager = startManager();
        await manager.connect();

        await manager.disconnectKeepingData();

        expect(fakeDatabase.disconnectCallCount, 1);
        expect(fakeDatabase.disconnectAndClearCallCount, 0);
      });

      test('does nothing when not connected', () async {
        final manager = startManager();

        await manager.disconnectKeepingData();

        expect(fakeDatabase.disconnectCallCount, 0);
      });

      test('clears the kept rows before the next connect', () async {
        final manager = startManager();
        await manager.connect();
        await manager.disconnectKeepingData();

        await manager.connect();

        expect(fakeDatabase.disconnectAndClearCallCount, 1);
        expect(fakeDatabase.lastClearLocal, isFalse);
        expect(fakeDatabase.connectCallCount, 2);
      });
    });

    test('a connect that fails throws and allows a later retry', () async {
      final manager = startManager();
      fakeDatabase.connectError = Exception('network down');

      await expectLater(manager.connect(), throwsException);
      expect(fakeDatabase.connectCallCount, 1);

      fakeDatabase.connectError = null;
      await manager.connect();
      expect(fakeDatabase.connectCallCount, 2);
    });

    test(
      'disconnectAndClear failure keeps the manager connected for a retry',
      () async {
        final manager = startManager();
        await manager.connect();
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

      await manager.disconnectAndClear();

      expect(fakeDatabase.disconnectAndClearCallCount, 0);
    });

    group('disconnectAndClearOrThrow', () {
      test('clears even when the manager is not connected', () async {
        final manager = startManager();

        await manager.disconnectAndClearOrThrow();

        expect(fakeDatabase.disconnectAndClearCallCount, 1);
        expect(fakeDatabase.lastClearLocal, isFalse);
      });

      test('throws when the clear fails', () async {
        final manager = startManager();
        fakeDatabase.disconnectAndClearError = Exception('disk error');

        await expectLater(manager.disconnectAndClearOrThrow(), throwsException);
      });

      test('connects again after a successful clear', () async {
        final manager = startManager();
        await manager.connect();

        await manager.disconnectAndClearOrThrow();
        await manager.connect();

        expect(fakeDatabase.connectCallCount, 2);
      });

      test('a failed clear is retried before the next connect', () async {
        final manager = startManager();
        await manager.connect();
        fakeDatabase.disconnectAndClearError = Exception('disk error');
        await expectLater(manager.disconnectAndClearOrThrow(), throwsException);

        fakeDatabase.disconnectAndClearError = null;
        await manager.connect();

        expect(fakeDatabase.disconnectAndClearCallCount, 2);
        expect(fakeDatabase.connectCallCount, 2);
      });
    });

    test('retries a failed clear before connecting the next user', () async {
      final manager = startManager();
      await manager.connect();
      expect(fakeDatabase.connectCallCount, 1);

      fakeDatabase.disconnectAndClearError = Exception('disk error');
      await manager.disconnectAndClear();
      expect(fakeDatabase.disconnectAndClearCallCount, 1);

      fakeDatabase.disconnectAndClearError = null;
      await manager.connect();

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
        final manager = startManager();
        await manager.connect();

        fakeDatabase.disconnectAndClearError = Exception('disk error');
        await manager.disconnectAndClear();

        await expectLater(manager.connect(), throwsStateError);

        expect(fakeDatabase.disconnectAndClearCallCount, 2);
        expect(
          fakeDatabase.connectCallCount,
          1,
          reason: 'must not sync a new user on top of the previous rows',
        );
      },
    );

    test(
      'serializes a clear that arrives during an in-flight connect',
      () async {
        final manager = startManager();
        final gate = Completer<void>();
        fakeDatabase.connectGate = gate.future;

        final connecting = manager.connect();
        final clearing = manager.disconnectAndClear();

        gate.complete();
        fakeDatabase.connectGate = null;
        await Future.wait([connecting, clearing]);

        expect(fakeDatabase.completedOperations, [
          'connect',
          'disconnectAndClear',
        ]);

        await manager.connect();

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
