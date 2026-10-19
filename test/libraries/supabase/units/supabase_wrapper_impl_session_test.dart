import 'dart:convert';

import 'package:construculator/libraries/config/testing/fake_env_loader.dart';
import 'package:construculator/libraries/secure_storage/testing/fake_secure_storage_wrapper.dart';
import 'package:construculator/libraries/supabase/supabase_wrapper_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

const _sessionKey = 'sb-testproject-auth-token';
const _accessToken = 'access-token-1';
const _refreshToken = 'refresh-token-1';
const _userId = 'user-1';

Map<String, dynamic> _sessionJson({
  String accessToken = _accessToken,
  String refreshToken = _refreshToken,
}) => {
  'access_token': accessToken,
  'token_type': 'bearer',
  'expires_in': 3600,
  'expires_at': 4102444800,
  'refresh_token': refreshToken,
  'user': {
    'id': _userId,
    'aud': 'authenticated',
    'email': 'user@example.com',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00Z',
  },
};

http.Response _response(int status, [Object? body]) =>
    // ignore: no_direct_instantiation, reason: http.Response is the fake auth server's reply type
    http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

// ignore: no_direct_instantiation, reason: MockClient is package:http's own fake network for tests
MockClient _authServer() => MockClient((request) async {
  if (request.url.path.endsWith('/logout')) return _response(204);
  return _response(200, _sessionJson());
});

SupabaseWrapperImpl buildWrapper(
  FakeSecureStorageWrapper secure,
  http.Client httpClient,
) {
  final env = FakeEnvLoader()
    ..setEnvVar('SUPABASE_URL', 'https://testproject.supabase.co')
    ..setEnvVar('SUPABASE_ANON_KEY', 'publishable-key');
  // ignore: no_direct_instantiation, reason: the wiring under test lives in this constructor and initialize()
  return SupabaseWrapperImpl(
    envLoader: env,
    secureStorage: secure,
    httpClient: httpClient,
  );
}

void main() {
  group('SupabaseWrapperImpl login session storage', () {
    late FakeSecureStorageWrapper secure;

    Future<Set<String>> preferenceKeys() async =>
        (await SharedPreferences.getInstance()).getKeys();

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      secure = FakeSecureStorageWrapper();
    });

    tearDown(() => supabase.Supabase.instance.dispose());

    test('a new sign-in stores no token in shared preferences', () async {
      final wrapper = buildWrapper(secure, _authServer());
      await wrapper.initialize();

      await wrapper.signInWithPassword(
        email: 'user@example.com',
        password: 'pw',
      );
      await secure.untilWritten(_sessionKey);

      final storedSession = secure.peek(_sessionKey);
      expect(storedSession, contains(_accessToken));
      expect(storedSession, contains(_refreshToken));
      expect(await preferenceKeys(), isEmpty);
    });

    test('a user signed in before the update stays signed in', () async {
      SharedPreferences.setMockInitialValues({
        _sessionKey: jsonEncode(_sessionJson()),
      });
      final wrapper = buildWrapper(secure, _authServer());

      await wrapper.initialize();

      expect(wrapper.currentSession?.accessToken, _accessToken);
      expect(wrapper.currentSession?.refreshToken, _refreshToken);
      expect(wrapper.currentUser?.id, _userId);
      expect(secure.peek(_sessionKey), contains(_refreshToken));
      expect(await preferenceKeys(), isEmpty);
    });

    test('a user already on secure storage stays signed in', () async {
      secure.seed(_sessionKey, jsonEncode(_sessionJson()));
      final wrapper = buildWrapper(secure, _authServer());

      await wrapper.initialize();

      expect(wrapper.currentUser?.id, _userId);
    });

    test('signing out removes the session from secure storage', () async {
      final wrapper = buildWrapper(secure, _authServer());
      await wrapper.initialize();
      await wrapper.signInWithPassword(
        email: 'user@example.com',
        password: 'pw',
      );
      await secure.untilWritten(_sessionKey);

      await wrapper.signOut();
      await secure.untilRemoved(_sessionKey);

      expect(secure.storedKeys, isEmpty);
      expect(await preferenceKeys(), isEmpty);
    });

    test(
      'a secure store that cannot be read starts the app signed out',
      () async {
        secure.seed(_sessionKey, jsonEncode(_sessionJson()));
        secure.shouldThrowOnRead = true;
        final wrapper = buildWrapper(secure, _authServer());

        await wrapper.initialize();

        expect(wrapper.currentSession, isNull);
      },
    );
  });
}
