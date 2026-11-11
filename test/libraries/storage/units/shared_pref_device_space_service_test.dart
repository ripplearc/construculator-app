import 'package:construculator/libraries/storage/models/device_setting.dart';
import 'package:construculator/libraries/storage/prefixed_preferences.dart';
import 'package:construculator/libraries/storage/shared_pref_device_space_service.dart';
import 'package:construculator/libraries/storage/shared_pref_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPrefDeviceSpaceService', () {
    late SharedPrefService userSpace;
    late SharedPrefDeviceSpaceService deviceSpace;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      // ignore: no_direct_instantiation, reason: the real service over the platform preferences is under test
      userSpace = SharedPrefService(
        // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
        preferences: PrefixedPreferences(prefix: SharedPrefService.keyPrefix),
      );
      // ignore: no_direct_instantiation, reason: the real service over the platform preferences is under test
      deviceSpace = SharedPrefDeviceSpaceService(
        // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
        preferences: PrefixedPreferences(
          prefix: SharedPrefDeviceSpaceService.keyPrefix,
        ),
      );
    });

    test('refuses preferences that use another prefix', () {
      expect(
        () =>
            // ignore: no_direct_instantiation, reason: the constructor guard is under test
            SharedPrefDeviceSpaceService(
              // ignore: no_direct_instantiation, reason: the real preferences wrapper is under test
              preferences: PrefixedPreferences(prefix: 'user.'),
            ),
        throwsAssertionError,
      );
    });

    test('reads back a saved setting', () async {
      await deviceSpace.saveSetting<bool>(DeviceSetting.onboardingSeen, true);

      expect(
        await deviceSpace.getSetting<bool>(DeviceSetting.onboardingSeen),
        isTrue,
      );
    });

    test('keeps a setting when the user space is cleared', () async {
      await deviceSpace.saveSetting<int>(DeviceSetting.hungRunCount, 2);
      await userSpace.saveData<String>('one', '1');

      await userSpace.clearAll();

      expect(await deviceSpace.getSetting<int>(DeviceSetting.hungRunCount), 2);
    });

    test('a setting and a user key of the same name do not mix', () async {
      await deviceSpace.saveSetting<String>(
        DeviceSetting.lastOpenedDate,
        'device',
      );
      await userSpace.saveData<String>('lastOpenedDate', 'user');

      expect(
        await deviceSpace.getSetting<String>(DeviceSetting.lastOpenedDate),
        'device',
      );
      expect(await userSpace.getData<String>('lastOpenedDate'), 'user');
    });

    test('two settings keep their own values', () async {
      await deviceSpace.saveSetting<int>(DeviceSetting.ownerChangeCount, 1);
      await deviceSpace.saveSetting<int>(DeviceSetting.hungRunCount, 2);

      expect(
        await deviceSpace.getSetting<int>(DeviceSetting.ownerChangeCount),
        1,
      );
      expect(await deviceSpace.getSetting<int>(DeviceSetting.hungRunCount), 2);
    });

    test('removeSetting forgets the setting', () async {
      await deviceSpace.saveSetting<bool>(DeviceSetting.onboardingSeen, true);

      await deviceSpace.removeSetting(DeviceSetting.onboardingSeen);

      expect(
        await deviceSpace.getSetting<bool>(DeviceSetting.onboardingSeen),
        isNull,
      );
    });

    test('refuses a value it cannot store', () async {
      await expectLater(
        deviceSpace.saveSetting<Object>(
          DeviceSetting.lastOpenedDate,
          DateTime(2026),
        ),
        throwsArgumentError,
      );
    });
  });
}
