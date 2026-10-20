import 'package:construculator/libraries/secure_storage/interfaces/secure_storage_wrapper.dart';
import 'package:flutter/services.dart';
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
/// session, which signs the user out.
/// On iOS the read throws, and [SecureStorageWrapper] logs it.
/// On Android the plugin (resetOnError, on by default) deletes the value
/// and returns null, so nothing is logged.
///
/// When [ignoreStoredSession] is true, whatever is stored reads as no session,
/// so the app starts signed out. A new sign-in saves over the stored value.
// TODO: [CA-1333] start Sentry before Supabase so the iOS start-up failure reaches Sentry
class SecureSessionLocalStorage extends LocalStorage {
  final SecureStorageWrapper _secureStorage;

  /// The key the session is saved under, in secure storage and in the old
  /// `shared_preferences` copy.
  final String persistSessionKey;

  /// Whether to treat the stored session as absent for this launch.
  ///
  /// Set when secure storage could not be emptied after a fresh install, so a
  /// previous user's session may still be in it.
  final bool ignoreStoredSession;

  /// Creates storage that saves the session under [persistSessionKey].
  const SecureSessionLocalStorage({
    required this._secureStorage,
    required this.persistSessionKey,
    this.ignoreStoredSession = false,
  });

  /// The key Supabase's default storage uses for [supabaseUrl].
  ///
  /// It must match the SDK's own key, or sessions saved by earlier app
  /// versions would not be found and every user would be signed out.
  static String persistSessionKeyFor(String supabaseUrl) =>
      'sb-${Uri.parse(supabaseUrl).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() async {
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
    if (ignoreStoredSession) return null;
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
