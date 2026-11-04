import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/network_status_service_impl.dart';
import 'package:construculator/libraries/network_status/testing/fake_connectivity_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeConnectivitySdk sdk;

  setUp(() {
    sdk = FakeConnectivitySdk();
    addTearDown(sdk.dispose);
  });

  NetworkStatusServiceImpl startService() {
    // ignore: no_direct_instantiation
    final service = NetworkStatusServiceImpl(connectivitySdk: sdk);
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

      test('stays online when the first reading fails', () async {
        sdk.shouldThrowOnCheck = true;

        final service = await createService();

        expect(service.current, NetworkStatus.online);
      });

      test(
        'keeps a change heard while the first reading was pending',
        () async {
          sdk.holdCheck();
          final service = startService();

          sdk.emit([ConnectivityResult.none]);
          await sdk.releaseCheck([ConnectivityResult.wifi]);
          await service.ready;

          expect(service.current, NetworkStatus.offline);
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
        test('$online reads as online', () async {
          sdk.emit([ConnectivityResult.none]);
          final service = await createService();

          sdk.emit(online);

          expect(service.current, NetworkStatus.online);
        });
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

    group('dispose', () {
      test(
        'a first reading that finishes after dispose changes nothing',
        () async {
          sdk.holdCheck();
          final service = startService();
          await service.dispose();

          await sdk.releaseCheck([ConnectivityResult.none]);

          expect(service.current, NetworkStatus.online);
        },
      );

      test('stops listening to the operating system', () async {
        final service = await createService();
        expect(sdk.hasListener, isTrue);

        await service.dispose();

        expect(sdk.hasListener, isFalse);
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
