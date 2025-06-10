import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeSupabaseWrapper Fake Implementations', () {
    group('FakeUser Implementation', () {
      test('constructor sets id, email, and createdAt correctly, with empty/null metadata by default', () {
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
        );

        expect(user.id, equals('test-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.createdAt, equals('2023-01-01T00:00:00Z'));
        expect(user.appMetadata, isEmpty, reason: "Default appMetadata should be empty");
        expect(user.userMetadata, isNull, reason: "Default userMetadata should be null");
      });

      test('constructor correctly assigns provided appMetadata and userMetadata', () {
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
          appMetadata: {'role': 'admin'},
          userMetadata: {'name': 'Test User'},
        );

        expect(user.appMetadata['role'], equals('admin'));
        expect(user.userMetadata!['name'], equals('Test User'));
      });
    });

    group('FakeAuthResponse Implementation', () {
      test('constructor correctly assigns user and session', () {
        final user = FakeUser(id: 'test-id', email: 'test@example.com', createdAt: 'now');
        final session = FakeSession(user: user);

        final response = FakeAuthResponse(user: user, session: session);

        expect(response.user, same(user));
        expect(response.session, same(session));
      });

      test('constructor handles null user and session', () {
        final response = FakeAuthResponse(user: null, session: null);

        expect(response.user, isNull);
        expect(response.session, isNull);
      });
    });

    group('FakeSession Implementation', () {
      test('constructor assigns user and provided tokens correctly', () {
        final user = FakeUser(id: 'test-id', email: 'test@example.com', createdAt: 'now');

        final session = FakeSession(
          user: user,
          accessToken: 'custom-access-token',
          refreshToken: 'custom-refresh-token',
        );

        expect(session.user, same(user));
        expect(session.accessToken, equals('custom-access-token'));
        expect(session.refreshToken, equals('custom-refresh-token'));
      });

      test('constructor uses default tokens if specific ones are not provided', () {
        final user = FakeUser(id: 'test-id', email: 'test@example.com', createdAt: 'now');
        final session = FakeSession(user: user);

        expect(session.user, same(user));
        expect(session.accessToken, equals('fake-access-token'), reason: "Should use default access token");
        expect(session.refreshToken, equals('fake-refresh-token'), reason: "Should use default refresh token");
      });
    });
  });
} 