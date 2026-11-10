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

    test('throws while shouldThrowOnDelete is set and still counts', () async {
      fake.shouldThrowOnDelete = true;

      await expectLater(
        fake.deleteSyncedDataAndUnsentEdits(),
        throwsStateError,
      );

      expect(fake.deleteCallCount, 1);
    });
  });
}
