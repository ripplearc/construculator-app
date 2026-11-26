import 'dart:convert';

import 'package:construculator/libraries/supabase/data/saved_session_read.dart';
import 'package:flutter_test/flutter_test.dart';

String _session({
  Object? user = const {'id': 'u1'},
  Object? accessToken = 'a1',
}) => json.encode({
  'access_token': accessToken,
  'token_type': 'bearer',
  'refresh_token': 'r1',
  'user': user,
});

void main() {
  group('SavedSessionFound.isReadableSession', () {
    test('is true for a value Supabase can load as a session', () {
      expect(SavedSessionFound(_session()).isReadableSession, isTrue);
    });

    test('is false for text that is not JSON', () {
      expect(const SavedSessionFound('{broken').isReadableSession, isFalse);
    });

    test('is false for JSON that is not an object', () {
      expect(const SavedSessionFound('[1,2]').isReadableSession, isFalse);
    });

    test('is false for a session with no access token', () {
      expect(
        SavedSessionFound(_session(accessToken: null)).isReadableSession,
        isFalse,
      );
    });

    test('is false for a session whose user is not an object', () {
      expect(
        SavedSessionFound(_session(user: 'u1')).isReadableSession,
        isFalse,
      );
    });

    test('is false for a session whose user has no id', () {
      expect(
        SavedSessionFound(_session(user: const {})).isReadableSession,
        isFalse,
      );
    });

    test('is false for a session with no token type', () {
      expect(
        const SavedSessionFound(
          '{"access_token":"a1","user":{"id":"u1"}}',
        ).isReadableSession,
        isFalse,
      );
    });
  });

  group('SavedSessionFound with a value Supabase also fails to load', () {
    test('is not readable when the user holds a field of the wrong type', () {
      const value =
          '{"access_token":"a","token_type":"bearer",'
          '"user":{"id":"u","identities":"abc"}}';

      expect(const SavedSessionFound(value).isReadableSession, isFalse);
    });

    test('does not print the saved text, which holds the tokens', () {
      expect(
        '${const SavedSessionFound('secret-token')}',
        isNot(contains('secret')),
      );
    });
  });

  group('SavedSessionFound.accessToken', () {
    test('is the access token of the saved session', () {
      expect(SavedSessionFound(_session()).accessToken, 'a1');
    });

    test('is null when the value is not a readable session', () {
      expect(const SavedSessionFound('{broken').accessToken, isNull);
    });
  });

  group('SavedSessionFound.userId', () {
    test('is the id of the user in the session', () {
      expect(SavedSessionFound(_session()).userId, 'u1');
    });

    test('is null when the value is not a readable session', () {
      expect(const SavedSessionFound('{broken').userId, isNull);
    });
  });
}
