import 'package:construculator/libraries/secure_storage/testing/fake_secure_storage_wrapper.dart';
import 'package:construculator/libraries/supabase/secure_session_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'sb-project-auth-token';
const _session = '{"access_token":"a1","refresh_token":"r1"}';

SecureSessionLocalStorage buildStorage(FakeSecureStorageWrapper secure) =>
    // ignore: no_direct_instantiation, reason: the class under test is built around the fake secure store
    SecureSessionLocalStorage(secureStorage: secure, persistSessionKey: _key);

void main() {
  group('SecureSessionLocalStorage', () {
    late FakeSecureStorageWrapper secure;
    late SecureSessionLocalStorage storage;

    Future<SharedPreferences> preferences() => SharedPreferences.getInstance();

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      secure = FakeSecureStorageWrapper();
      storage = buildStorage(secure);
    });

    group('persistSessionKeyFor', () {
      test('names the key after the project part of a hosted URL', () {
        expect(
          SecureSessionLocalStorage.persistSessionKeyFor(
            'https://abcdefgh.supabase.co',
          ),
          'sb-abcdefgh-auth-token',
        );
      });

      test('names the key after the first part of a local address', () {
        expect(
          SecureSessionLocalStorage.persistSessionKeyFor(
            'http://127.0.0.1:54321',
          ),
          'sb-127-auth-token',
        );
      });
    });

    group('persisting a session', () {
      test('keeps the session in secure storage', () async {
        await storage.persistSession(_session);

        expect(secure.peek(_key), _session);
        expect(await storage.accessToken(), _session);
        expect(await storage.hasAccessToken(), isTrue);
      });

      test('writes nothing to shared preferences', () async {
        await storage.persistSession(_session);

        expect((await preferences()).getKeys(), isEmpty);
      });

      test('reports a failed save instead of hiding it', () async {
        secure.shouldThrowOnWrite = true;

        await expectLater(storage.persistSession(_session), throwsException);
      });
    });

    group('reading the session', () {
      test('reports no session when nothing was saved', () async {
        expect(await storage.hasAccessToken(), isFalse);
        expect(await storage.accessToken(), isNull);
      });

      test('treats a session that cannot be read as no session', () async {
        secure.seed(_key, _session);
        secure.shouldThrowOnRead = true;

        expect(await storage.hasAccessToken(), isFalse);
        expect(await storage.accessToken(), isNull);
      });
    });

    group('when the stored session is to be ignored', () {
      late SecureSessionLocalStorage ignoring;

      setUp(() {
        secure.seed(_key, _session);
        // ignore: no_direct_instantiation, reason: the class under test is built around the fake secure store
        ignoring = SecureSessionLocalStorage(
          secureStorage: secure,
          persistSessionKey: _key,
          ignoreStoredSession: true,
        );
      });

      test('reports no session although one is stored', () async {
        expect(await ignoring.accessToken(), isNull);
        expect(await ignoring.hasAccessToken(), isFalse);
      });

      test('keeps a session saved by a new sign-in', () async {
        await ignoring.persistSession('{"access_token":"a2"}');

        expect(secure.peek(_key), '{"access_token":"a2"}');
      });

      test('signing out still removes the stored session', () async {
        await ignoring.removePersistedSession();

        expect(secure.storedKeys, isEmpty);
      });
    });

    group('removing the session', () {
      test('clears secure storage', () async {
        secure.seed(_key, _session);

        await storage.removePersistedSession();

        expect(secure.peek(_key), isNull);
        expect(await storage.hasAccessToken(), isFalse);
      });

      test('clears an old shared preferences copy as well', () async {
        SharedPreferences.setMockInitialValues({_key: _session});
        secure.seed(_key, _session);

        await storage.removePersistedSession();

        expect((await preferences()).containsKey(_key), isFalse);
      });

      test('reports a failed delete instead of hiding it', () async {
        secure.seed(_key, _session);
        secure.shouldThrowOnDelete = true;

        await expectLater(storage.removePersistedSession(), throwsException);
      });
    });

    group('moving a session saved by an earlier app version', () {
      setUp(() => SharedPreferences.setMockInitialValues({_key: _session}));

      test('keeps the user signed in', () async {
        await storage.initialize();

        expect(await storage.accessToken(), _session);
        expect(await storage.hasAccessToken(), isTrue);
      });

      test('deletes the old shared preferences copy', () async {
        await storage.initialize();

        expect((await preferences()).containsKey(_key), isFalse);
      });

      test('keeps the newer secure session when both exist', () async {
        secure.seed(_key, '{"access_token":"a2","refresh_token":"r2"}');

        await storage.initialize();

        expect(secure.peek(_key), '{"access_token":"a2","refresh_token":"r2"}');
        expect((await preferences()).containsKey(_key), isFalse);
      });

      test(
        'keeps the old copy when it cannot be saved, then retries',
        () async {
          secure.shouldThrowOnWrite = true;
          await storage.initialize();
          expect((await preferences()).getString(_key), _session);
          expect(secure.peek(_key), isNull);

          secure.shouldThrowOnWrite = false;
          await storage.initialize();

          expect(secure.peek(_key), _session);
          expect((await preferences()).containsKey(_key), isFalse);
        },
      );

      test('keeps the old copy when secure storage cannot be read', () async {
        secure.shouldThrowOnRead = true;

        await storage.initialize();

        expect((await preferences()).getString(_key), _session);
      });

      test('does nothing when there is no old copy', () async {
        SharedPreferences.setMockInitialValues({});

        await storage.initialize();

        expect(secure.storedKeys, isEmpty);
      });
    });
  });
}
