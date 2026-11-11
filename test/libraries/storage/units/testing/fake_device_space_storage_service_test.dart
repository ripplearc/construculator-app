import 'package:construculator/libraries/storage/models/device_setting.dart';
import 'package:construculator/libraries/storage/testing/fake_device_space_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeDeviceSpaceStorageService', () {
    late FakeDeviceSpaceStorageService fake;

    setUp(() => fake = FakeDeviceSpaceStorageService());

    test('reads back a saved setting and exposes it through valueOf', () async {
      await fake.saveSetting<bool>(DeviceSetting.onboardingSeen, true);

      expect(await fake.getSetting<bool>(DeviceSetting.onboardingSeen), isTrue);
      expect(fake.valueOf(DeviceSetting.onboardingSeen), isTrue);
    });

    test('a value of another type reads as nothing', () async {
      await fake.saveSetting<int>(DeviceSetting.hungRunCount, 1);

      expect(await fake.getSetting<String>(DeviceSetting.hungRunCount), isNull);
    });

    test('removeSetting forgets the setting', () async {
      await fake.saveSetting<int>(DeviceSetting.hungRunCount, 1);

      await fake.removeSetting(DeviceSetting.hungRunCount);

      expect(fake.valueOf(DeviceSetting.hungRunCount), isNull);
    });

    test('a read fails while shouldThrowOnRead is set', () async {
      fake.shouldThrowOnRead = true;

      await expectLater(
        fake.getSetting<bool>(DeviceSetting.onboardingSeen),
        throwsStateError,
      );
    });

    test(
      'a write fails and stores nothing while shouldThrowOnWrite is set',
      () async {
        fake.shouldThrowOnWrite = true;

        await expectLater(
          fake.saveSetting<bool>(DeviceSetting.onboardingSeen, true),
          throwsStateError,
        );
        expect(fake.valueOf(DeviceSetting.onboardingSeen), isNull);
      },
    );

    test('reset clears the settings and the failure switches', () async {
      await fake.saveSetting<int>(DeviceSetting.hungRunCount, 1);
      fake.shouldThrowOnRead = true;
      fake.shouldThrowOnWrite = true;

      fake.reset();

      expect(fake.valueOf(DeviceSetting.hungRunCount), isNull);
      expect(await fake.getSetting<int>(DeviceSetting.hungRunCount), isNull);
      await fake.saveSetting<int>(DeviceSetting.hungRunCount, 2);
      expect(fake.valueOf(DeviceSetting.hungRunCount), 2);
    });
  });
}
