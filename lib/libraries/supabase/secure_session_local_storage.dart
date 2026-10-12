import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the Supabase login session (access and refresh token) in
/// [SecureStorageWrapper] instead of the SDK's default `shared_preferences`.
///
/// A session saved by an earlier app version sits in `shared_preferences`
/// under the same key. [initialize] moves it into secure storage and deletes
/// the old copy, so signed-in users stay signed in. If the move fails, the old
/// copy stays and the move is tried again on the next launch.
///
/// Supabase calls [hasAccessToken] while starting the app and does not catch
/// errors from it. A session that cannot be read therefore reads as no
/// session, which signs the user out, rather than stopping the app from
/// starting. [SecureStorageWrapper] logs that failure, but Sentry is not
/// running yet at that point, so the log reaches the console only.
class SecureSessionLocalStorage extends LocalStorage {
  final SecureStorageWrapper _secureStorage;

  /// The key the session is saved under, in secure storage and in the old
  /// `shared_preferences` copy.
  final String persistSessionKey;

  /// Creates storage that saves the session under [persistSessionKey].
  const SecureSessionLocalStorage({
    required this._secureStorage,
    required this.persistSessionKey,
  });

  /// The key Supabase's default storage uses for [supabaseUrl].
  ///
  /// It must match the SDK's own key, or sessions saved by earlier app
  /// versions would not be found and every user would be signed out.
  static String persistSessionKeyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    final legacySession = preferences.getString(persistSessionKey);
    if (legacySession == null) return;
    try {
      if (await _secureStorage.read(persistSessionKey) == null) {
        await _secureStorage.write(persistSessionKey, legacySession);
      }
    } on PlatformException {
      return;
    }
    await preferences.remove(persistSessionKey);
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _secureStorage.read(persistSessionKey);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) =>
      _secureStorage.write(persistSessionKey, persistSessionString);

  @override
  Future<void> removePersistedSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(persistSessionKey);
    await _secureStorage.delete(persistSessionKey);
  }
}
