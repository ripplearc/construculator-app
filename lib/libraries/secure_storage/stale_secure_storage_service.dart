import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Empties secure storage on the first launch after a fresh install.
///
/// iOS keeps Keychain items when an app is uninstalled, so a reinstall could
/// otherwise start with the previous user's session. `shared_preferences` is
/// deleted with the app, which makes a missing first-run flag the sign of a
/// fresh install.
///
/// The flag did not exist before this check shipped, so an update also has no
/// flag. A key written by an earlier app version tells the two apart: an
/// update still has it and keeps its secure storage.
///
/// If emptying secure storage fails, the flag stays unset and the next launch
/// tries again. The caller is told the store may still hold the previous
/// user's session, so that launch can start signed out. [SecureStorageWrapper]
/// logs the failure, but Sentry is not running yet at that point, so the log
/// reaches the console only.
class StaleSecureStorageService {
  static const _hasLaunchedBeforeKey = 'has_launched_before';

  final SecureStorageWrapper _secureStorage;

  /// Creates a service that empties [secureStorage] on a fresh install.
  const StaleSecureStorageService({required this._secureStorage});

  /// Empties secure storage when this is a fresh install, then records that
  /// the app has launched.
  ///
  /// [earlierVersionKey] is a `shared_preferences` key an earlier app version
  /// wrote. Finding it means the app is being updated, not freshly installed.
  ///
  /// Returns false when emptying secure storage failed, so a previous user's
  /// session may still be in it. Returns true otherwise.
  Future<bool> clearIfFreshInstall({required String earlierVersionKey}) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_hasLaunchedBeforeKey) ?? false) return true;
    if (!preferences.containsKey(earlierVersionKey)) {
      try {
        await _secureStorage.deleteAll();
      } on PlatformException {
        return false;
      }
    }
    await preferences.setBool(_hasLaunchedBeforeKey, true);
    return true;
  }
}
