import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/app_lifecycle/testing/fake_app_lifecycle_wrapper.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/network_status_service_impl.dart';
import 'package:construculator/libraries/network_status/testing/fake_connectivity_sdk.dart';
import 'package:construculator/libraries/network_status/testing/fake_internet_reachability_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeConnectivitySdk sdk;
  late FakeInternetReachabilitySdk reachability;
  late FakeAppLifecycleWrapper lifecycle;

  setUp(() {
    sdk = FakeConnectivitySdk();
    reachability = FakeInternetReachabilitySdk();
    lifecycle = FakeAppLifecycleWrapper();
    addTearDown(sdk.dispose);
    addTearDown(reachability.dispose);
  });

  NetworkStatusServiceImpl startService() {
    // ignore: no_direct_instantiation
    final service = NetworkStatusServiceImpl(
      connectivitySdk: sdk,
      reachabilitySdk: reachability,
      appLifecycle: lifecycle,
    );
    addTearDown(service.dispose);
    return service;
  }

  Future<NetworkStatusServiceImpl> createService() async {
    final service = startService();
    await service.ready;
    return service;
  }

  group('NetworkStatusServiceImpl', () {
    group('initial status', () {
      test('is online when the phone starts on Wi-Fi', () async {
        final service = await createService();

        expect(service.current, NetworkStatus.online);
      });

      test('is offline when the phone starts with no network', () async {
        sdk.emit([ConnectivityResult.none]);

        final service = await createService();

        expect(service.current, NetworkStatus.offline);
      });

      test('is offline when the system reports no networks at all', () async {
        sdk.emit([]);

        final service = await createService();

        expect(service.current, NetworkStatus.offline);
      });

      test('checks the internet anyway when the first reading fails', () async {
        sdk.shouldThrowOnCheck = true;

        final service = await createService();

        expect(service.current, NetworkStatus.online);
        expect(reachability.checkCount, 1);
        expect(reachability.isPolling, isTrue);
      });

      test(
        'does not start checking after a failed first reading if a change was heard',
        () async {
          sdk.holdCheck();
          sdk.shouldThrowOnCheck = true;
          final service = startService();
          sdk.emit([ConnectivityResult.none]);
          sdk.shouldThrowOnCheck = false;

          await service.ready;

          expect(service.current, NetworkStatus.offline);
          expect(reachability.isPolling, isFalse);
        },
      );

      test(
        'keeps a change heard while the first reading was pending',
        () async {
          sdk.holdCheck();
          final service = startService();

          sdk.emit([ConnectivityResult.none]);
          sdk.releaseCheck([ConnectivityResult.wifi]);
          await service.ready;

          expect(service.current, NetworkStatus.offline);
          expect(reachability.checkCount, 0);
        },
      );
    });

    group('mapping system values', () {
      for (final online in [
        [ConnectivityResult.wifi],
        [ConnectivityResult.mobile],
        [ConnectivityResult.ethernet],
        [ConnectivityResult.vpn],
        [ConnectivityResult.bluetooth],
        [ConnectivityResult.other],
        [ConnectivityResult.satellite],
        [ConnectivityResult.wifi, ConnectivityResult.mobile],
        [ConnectivityResult.none, ConnectivityResult.wifi],
      ]) {
        test(
          '$online is checked and reads as online when the check passes',
          () async {
            sdk.emit([ConnectivityResult.none]);
            final service = await createService();
            reachability.holdChecks();
            final next = service.changes.first;

            sdk.emit(online);
            await reachability.releaseCheck(true);

            expect(await next, NetworkStatus.online);
          },
        );
      }

      test('none reads as offline', () async {
        final service = await createService();

        sdk.emit([ConnectivityResult.none]);

        expect(service.current, NetworkStatus.offline);
      });

      test('a list of only none values reads as offline', () async {
        final service = await createService();

        sdk.emit([ConnectivityResult.none, ConnectivityResult.none]);

        expect(service.current, NetworkStatus.offline);
      });
    });

    group('changes', () {
      test('emits each time the status flips', () async {
        final service = await createService();

        final emissions = expectLater(
          service.changes,
          emitsInOrder([NetworkStatus.offline, NetworkStatus.online]),
        );
        sdk.emit([ConnectivityResult.none]);
        sdk.emit([ConnectivityResult.mobile]);

        await emissions;
      });

      test('does not emit when the system reports the same status', () async {
        final service = await createService();
        final emitted = service.changes.toList();

        sdk.emit([ConnectivityResult.mobile]);
        sdk.emit([ConnectivityResult.wifi, ConnectivityResult.mobile]);
        sdk.emit([ConnectivityResult.none]);
        sdk.emit([ConnectivityResult.none]);
        await service.dispose();

        expect(await emitted, [NetworkStatus.offline]);
      });

      test('does not emit when the first change matches the start', () async {
        final service = await createService();
        final emitted = service.changes.toList();

        sdk.emit([ConnectivityResult.wifi]);
        await service.dispose();

        expect(await emitted, isEmpty);
      });
    });

    group('checking that the internet works', () {
      test(
        'a network that appears stays offline until the check passes',
        () async {
          sdk.emit([ConnectivityResult.none]);
          final service = await createService();
          reachability.holdChecks();

          sdk.emit([ConnectivityResult.wifi]);
          expect(service.current, NetworkStatus.offline);

          final next = service.changes.first;
          await reachability.releaseCheck(true);

          expect(await next, NetworkStatus.online);
        },
      );

      test('a network that cannot reach the internet stays offline', () async {
        sdk.emit([ConnectivityResult.none]);
        final service = await createService();
        reachability.holdChecks();
        final emitted = service.changes.toList();

        sdk.emit([ConnectivityResult.wifi]);
        await reachability.releaseCheck(false);
        await service.dispose();

        expect(await emitted, isEmpty);
        expect(service.current, NetworkStatus.offline);
      });

      test(
        'a network that is already online goes offline when the check fails',
        () async {
          reachability.holdChecks();
          final service = startService();
          await service.ready;
          final next = service.changes.first;

          await reachability.releaseCheck(false);

          expect(await next, NetworkStatus.offline);
        },
      );

      test('switching between networks checks again', () async {
        final service = await createService();
        final checksBefore = reachability.checkCount;

        sdk.emit([ConnectivityResult.mobile]);

        expect(reachability.checkCount, checksBefore + 1);
        await service.dispose();
      });

      test('losing the network ends a check still waiting', () async {
        sdk.emit([ConnectivityResult.none]);
        final service = await createService();
        reachability.holdChecks();
        sdk.emit([ConnectivityResult.wifi]);

        sdk.emit([ConnectivityResult.none]);
        await reachability.releaseCheck(true);

        expect(service.current, NetworkStatus.offline);
      });

      test(
        'an older check that finishes late does not overrule a newer one',
        () async {
          sdk.emit([ConnectivityResult.none]);
          final service = await createService();
          reachability.holdChecks();
          sdk.emit([ConnectivityResult.wifi]);
          sdk.emit([ConnectivityResult.mobile]);
          final next = service.changes.first;

          await reachability.releaseNewestCheck(true);
          expect(await next, NetworkStatus.online);
          await reachability.releaseCheck(false);

          expect(service.current, NetworkStatus.online);
        },
      );

      test('a failed check leaves the status as it was', () async {
        reachability.shouldThrowOnCheck = true;

        final service = await createService();

        expect(service.current, NetworkStatus.online);
      });
    });

    group('checking on a timer', () {
      test(
        'starts when a network is attached and the app is on screen',
        () async {
          await createService();

          expect(reachability.isPolling, isTrue);
        },
      );

      test('keeps one timer when the network switches', () async {
        await createService();
        sdk.emit([ConnectivityResult.mobile]);
        sdk.emit([ConnectivityResult.wifi]);
        final checksBefore = reachability.checkCount;

        reachability.tick();

        expect(reachability.checkCount, checksBefore + 1);
      });

      test('checks again on each tick and reports the answer', () async {
        final service = await createService();
        reachability.holdChecks();

        final goesOffline = service.changes.first;
        reachability.tick();
        await reachability.releaseCheck(false);
        expect(await goesOffline, NetworkStatus.offline);

        final comesBack = service.changes.first;
        reachability.tick();
        await reachability.releaseCheck(true);
        expect(await comesBack, NetworkStatus.online);
      });

      test(
        'recovers after a check at a network change found no internet',
        () async {
          final service = await createService();
          reachability.holdChecks();
          final goesOffline = service.changes.first;
          sdk.emit([ConnectivityResult.mobile]);
          await reachability.releaseCheck(false);
          expect(await goesOffline, NetworkStatus.offline);

          final comesBack = service.changes.first;
          reachability.tick();
          await reachability.releaseCheck(true);

          expect(await comesBack, NetworkStatus.online);
        },
      );

      test(
        'ignores a tick check that finishes after the network was lost',
        () async {
          final service = await createService();
          reachability.holdChecks();
          reachability.tick();

          sdk.emit([ConnectivityResult.none]);
          await reachability.releaseCheck(true);

          expect(service.current, NetworkStatus.offline);
        },
      );

      test(
        'ignores a check that finishes after the app went to the background',
        () async {
          final service = await createService();
          reachability.holdChecks();
          reachability.tick();

          lifecycle.setInForeground(false);
          await reachability.releaseCheck(false);

          expect(service.current, NetworkStatus.online);
        },
      );

      test('does not start when there is no network', () async {
        sdk.emit([ConnectivityResult.none]);

        await createService();

        expect(reachability.isPolling, isFalse);
      });

      test('stops when the network is lost', () async {
        await createService();

        sdk.emit([ConnectivityResult.none]);

        expect(reachability.isPolling, isFalse);
      });

      test('does not start when the app begins in the background', () async {
        lifecycle.setInForeground(false);

        await createService();

        expect(reachability.isPolling, isFalse);
      });

      test('stops in the background', () async {
        await createService();

        lifecycle.setInForeground(false);

        expect(reachability.isPolling, isFalse);
      });

      test('starts again with a check when the app comes back', () async {
        await createService();
        lifecycle.setInForeground(false);
        final checksBefore = reachability.checkCount;

        lifecycle.setInForeground(true);

        expect(reachability.isPolling, isTrue);
        expect(reachability.checkCount, checksBefore + 1);
      });

      test('does not check when the app comes back with no network', () async {
        await createService();
        lifecycle.setInForeground(false);
        sdk.emit([ConnectivityResult.none]);
        final checksBefore = reachability.checkCount;

        lifecycle.setInForeground(true);

        expect(reachability.isPolling, isFalse);
        expect(reachability.checkCount, checksBefore);
      });

      test(
        'waits for the app to come back before checking a new network',
        () async {
          sdk.emit([ConnectivityResult.none]);
          await createService();
          lifecycle.setInForeground(false);
          final checksBefore = reachability.checkCount;

          sdk.emit([ConnectivityResult.wifi]);

          expect(reachability.isPolling, isFalse);
          expect(reachability.checkCount, checksBefore);
        },
      );
    });

    group('dispose', () {
      test('stops listening to the operating system', () async {
        final service = await createService();
        expect(sdk.hasListener, isTrue);

        await service.dispose();

        expect(sdk.hasListener, isFalse);
      });

      test('stops the timer', () async {
        final service = await createService();

        await service.dispose();

        expect(reachability.isPolling, isFalse);
      });

      test('a first reading that finishes after dispose is ignored', () async {
        sdk.holdCheck();
        final service = startService();
        await service.dispose();

        await sdk.releaseCheck([ConnectivityResult.wifi]);

        expect(reachability.isPolling, isFalse);
        expect(reachability.checkCount, 0);
      });

      test(
        'a no-network first reading after dispose changes nothing',
        () async {
          sdk.holdCheck();
          final service = startService();
          await service.dispose();

          await sdk.releaseCheck([ConnectivityResult.none]);

          expect(service.current, NetworkStatus.online);
        },
      );

      test('a check that finishes after dispose changes nothing', () async {
        final service = await createService();
        reachability.holdChecks();
        reachability.tick();
        await service.dispose();

        await reachability.releaseCheck(false);

        expect(service.current, NetworkStatus.online);
      });

      test('stops reacting to the app lifecycle', () async {
        final service = await createService();
        await service.dispose();
        final checksBefore = reachability.checkCount;

        lifecycle.setInForeground(false);
        lifecycle.setInForeground(true);

        expect(reachability.checkCount, checksBefore);
      });

      test('closes changes', () async {
        final service = await createService();

        final done = expectLater(service.changes, emitsDone);
        await service.dispose();

        await done;
      });
    });
  });
}
