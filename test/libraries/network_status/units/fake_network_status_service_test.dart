import 'package:construculator/libraries/network_status/interfaces/network_status.dart';
import 'package:construculator/libraries/network_status/testing/fake_network_status_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeNetworkStatusService fake;

  setUp(() {
    fake = FakeNetworkStatusService();
    addTearDown(fake.dispose);
  });

  group('FakeNetworkStatusService', () {
    test('starts online', () {
      expect(fake.current, NetworkStatus.online);
    });

    test('emits to listeners when the status is set', () async {
      final emissions = expectLater(
        fake.changes,
        emitsInOrder([NetworkStatus.offline, NetworkStatus.online]),
      );

      fake.setStatus(NetworkStatus.offline);
      fake.setStatus(NetworkStatus.online);

      await emissions;
    });

    test('updates current when the status is set', () {
      fake.setStatus(NetworkStatus.offline);

      expect(fake.current, NetworkStatus.offline);
    });

    test('does not emit when the status is set to its current value', () {
      final emitted = <NetworkStatus>[];
      fake.changes.listen(emitted.add);

      fake.setStatus(NetworkStatus.online);

      expect(emitted, isEmpty);
    });

    test('reset returns to online', () {
      fake.setStatus(NetworkStatus.offline);

      fake.reset();

      expect(fake.current, NetworkStatus.online);
    });
  });
}
