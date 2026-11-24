import 'package:construculator/libraries/powersync/testing/fake_synced_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeSyncedDataService', () {
    late FakeSyncedDataService fake;

    setUp(() => fake = FakeSyncedDataService());

    test('counts each delete', () async {
      await fake.deleteSyncedDataAndUnsentEdits();
      await fake.deleteSyncedDataAndUnsentEdits();

      expect(fake.deleteCallCount, 2);
    });

    test('calls afterDelete after each successful delete', () async {
      var calls = 0;
      fake.afterDelete = () => calls++;

      await fake.deleteSyncedDataAndUnsentEdits();

      expect(calls, 1);
    });

    test('does not call afterDelete when the delete throws', () async {
      var calls = 0;
      fake.afterDelete = () => calls++;
      fake.shouldThrowOnDelete = true;

      await expectLater(fake.deleteSyncedDataAndUnsentEdits(), throwsException);

      expect(calls, 0);
    });

    test('throws while shouldThrowOnDelete is set and still counts', () async {
      fake.shouldThrowOnDelete = true;

      await expectLater(fake.deleteSyncedDataAndUnsentEdits(), throwsException);

      expect(fake.deleteCallCount, 1);
    });
  });
}
