import 'package:construculator/libraries/powersync/testing/fake_powersync_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakePowerSyncManager', () {
    test('calls onConnect when connect starts, before it fails', () async {
      final fake = FakePowerSyncManager()..shouldThrowOnConnect = true;
      var calls = 0;
      fake.onConnect = () => calls++;

      await expectLater(fake.connect(), throwsStateError);

      expect(calls, 1);
      expect(fake.connectCallCount, 1);
    });
  });
}
