import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// [SecureStorageWrapper] backed by the flutter_secure_storage plugin.
///
/// iOS items use `first_unlock_this_device`: readable after the first unlock
/// since boot, so a background refresh can read the session while the phone is
/// locked, and never synced to iCloud Keychain or moved to another device.
/// Android uses the plugin default, an RSA-OAEP wrapped AES-GCM key held in
/// the Keystore.
///
/// A failed call is logged once here and rethrown, so the caller decides
/// whether the failure matters. A failure before Sentry has started reaches
/// the console only.
class SecureStorageWrapperImpl implements SecureStorageWrapper {
  // TODO: [CA-1332] back to a static final once AppLogger reads the Sentry wrapper when it logs
  AppLogger get _logger => AppLogger().tag('SecureStorageWrapperImpl');

  final FlutterSecureStorage _storage;

  /// [storage] stands in for the plugin in tests; production omits it.
  SecureStorageWrapperImpl({FlutterSecureStorage? storage})
    : _storage = storage ?? defaultStorage;

  /// The Keychain options every item is written with.
  static const iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  /// The plugin store production uses, exposed so a test can check its options.
  @visibleForTesting
  static const defaultStorage = FlutterSecureStorage(iOptions: iosOptions);

  @override
  Future<String?> read(String key) =>
      _guard('read', () => _storage.read(key: key));

  @override
  Future<void> write(String key, String value) =>
      _guard('write', () => _storage.write(key: key, value: value));

  @override
  Future<void> delete(String key) =>
      _guard('delete', () => _storage.delete(key: key));

  Future<T> _guard<T>(String operation, Future<T> Function() run) async {
    try {
      return await run();
    } on PlatformException catch (e, stackTrace) {
      _logger.error('Secure storage $operation failed', e, stackTrace);
      rethrow;
    }
  }
}
