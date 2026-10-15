import 'package:construculator/libraries/secure_storage/secure_storage_wrapper_impl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFailingFlutterSecureStorage extends FlutterSecureStorage {
  const _FakeFailingFlutterSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'keystore_unavailable');

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'keystore_unavailable');

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'keystore_unavailable');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: 'keystore_unavailable');
}

SecureStorageWrapperImpl buildWrapper({FlutterSecureStorage? storage}) =>
    // ignore: no_direct_instantiation, reason: the wrapper under test takes the plugin store as its only seam
    SecureStorageWrapperImpl(storage: storage);

void main() {
  group('SecureStorageWrapperImpl', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('reads back a value it wrote', () async {
      final wrapper = buildWrapper();

      await wrapper.write('session', 'token-1');

      expect(await wrapper.read('session'), 'token-1');
    });

    test('replaces an earlier value under the same key', () async {
      final wrapper = buildWrapper();
      await wrapper.write('session', 'token-1');

      await wrapper.write('session', 'token-2');

      expect(await wrapper.read('session'), 'token-2');
    });

    test('reads null for a key that was never written', () async {
      expect(await buildWrapper().read('missing'), isNull);
    });

    test('keeps keys apart', () async {
      final wrapper = buildWrapper();
      await wrapper.write('a', '1');
      await wrapper.write('b', '2');

      await wrapper.delete('a');

      expect(await wrapper.read('a'), isNull);
      expect(await wrapper.read('b'), '2');
    });

    test('deleteAll removes every key', () async {
      final wrapper = buildWrapper();
      await wrapper.write('a', '1');
      await wrapper.write('b', '2');

      await wrapper.deleteAll();

      expect(await wrapper.read('a'), isNull);
      expect(await wrapper.read('b'), isNull);
    });

    test('deleting a key that is not there does not throw', () async {
      await expectLater(buildWrapper().delete('missing'), completes);
    });

    test('items are readable after first unlock and stay on this device', () {
      expect(
        SecureStorageWrapperImpl.iosOptions.toMap()['accessibility'],
        KeychainAccessibility.first_unlock_this_device.name,
      );
    });

    group('when the platform store fails', () {
      late SecureStorageWrapperImpl wrapper;

      setUp(
        () => wrapper = buildWrapper(
          storage: const _FakeFailingFlutterSecureStorage(),
        ),
      );

      test('read rethrows so the caller can decide', () {
        expect(() => wrapper.read('k'), throwsA(isA<PlatformException>()));
      });

      test('write rethrows so a lost session is not hidden', () {
        expect(
          () => wrapper.write('k', 'v'),
          throwsA(isA<PlatformException>()),
        );
      });

      test('delete rethrows so a surviving session is not hidden', () {
        expect(() => wrapper.delete('k'), throwsA(isA<PlatformException>()));
      });

      test('deleteAll rethrows so a surviving session is not hidden', () {
        expect(() => wrapper.deleteAll(), throwsA(isA<PlatformException>()));
      });
    });
  });
}
