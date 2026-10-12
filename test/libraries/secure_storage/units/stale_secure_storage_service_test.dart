import 'package:construculator/libraries/secure_storage/stale_secure_storage_service.dart';
import 'package:construculator/libraries/secure_storage/testing/fake_secure_storage_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _earlierVersionKey = 'sb-project-auth-token';

StaleSecureStorageService buildService(FakeSecureStorageWrapper secure) =>
    // ignore: no_direct_instantiation, reason: the service under test is built around the fake secure store
    StaleSecureStorageService(secureStorage: secure);

void main() {
  group('StaleSecureStorageService', () {
    late FakeSecureStorageWrapper secure;
    late StaleSecureStorageService service;

    Future<void> launch() =>
        service.clearIfFreshInstall(earlierVersionKey: _earlierVersionKey);

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      secure = FakeSecureStorageWrapper();
      service = buildService(secure);
    });

    test('empties items a previous install left in the Keychain', () async {
      secure.seed('stale', 'previous-user');

      await launch();

      expect(secure.storedKeys, isEmpty);
    });

    test(
      'keeps secure storage when an earlier app version is updated',
      () async {
        SharedPreferences.setMockInitialValues({_earlierVersionKey: 'session'});
        secure.seed('kept', 'value');

        await launch();

        expect(secure.peek('kept'), 'value');
      },
    );

    test('empties secure storage only on the first launch', () async {
      await launch();
      secure.seed('written-after-first-launch', 'value');

      await launch();

      expect(secure.peek('written-after-first-launch'), 'value');
    });

    test(
      'an updated app is not treated as fresh once the old key is gone',
      () async {
        SharedPreferences.setMockInitialValues({_earlierVersionKey: 'session'});
        await launch();
        await (await SharedPreferences.getInstance()).remove(
          _earlierVersionKey,
        );
        secure.seed('kept', 'value');

        await launch();

        expect(secure.peek('kept'), 'value');
      },
    );

    group('when secure storage cannot be emptied', () {
      setUp(() {
        secure.seed('stale', 'previous-user');
        secure.shouldThrowOnDelete = true;
      });

      test('does not stop the app from starting', () async {
        await expectLater(launch(), completes);
      });

      test('tries again on the next launch', () async {
        await launch();
        secure.shouldThrowOnDelete = false;

        await launch();

        expect(secure.storedKeys, isEmpty);
      });
    });
  });
}
