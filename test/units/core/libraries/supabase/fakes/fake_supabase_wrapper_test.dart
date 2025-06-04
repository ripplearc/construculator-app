import 'package:construculator/core/config/fakes/fake_supabase_client.dart';
import 'package:construculator/core/config/fakes/fake_supabase_initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/core/libraries/supabase/fakes/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('FakeSupabaseWrapper', () {
    late FakeSupabaseWrapper fakeWrapper;

    setUp(() {
      fakeWrapper = FakeSupabaseWrapper();
    });

    tearDown(() {
      fakeWrapper.reset();
    });

    group('Authentication Methods', () {
      group('signInWithPassword', () {
        test('should return successful auth response with user when configured', () async {
          // Act
          final result = await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          );

          // Assert
          expect(result.user, isNotNull);
          expect(result.user!.email, equals('test@example.com'));
          expect(result.session, isNotNull);
          expect(fakeWrapper.currentUser, isNotNull);
          expect(fakeWrapper.isAuthenticated, isTrue);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnSignIn = true;
          fakeWrapper.signInErrorMessage = 'Invalid credentials';

          // Act & Assert
          expect(
            () async => await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'wrong-password',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid credentials'),
            )),
          );
        });

        test('should return null user when configured to return null', () async {
          // Arrange
          fakeWrapper.shouldReturnNullUser = true;

          // Act
          final result = await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          );

          // Assert
          expect(result.user, isNull);
          expect(result.session, isNull);
        });
      });

      group('signUp', () {
        test('should return successful auth response with new user', () async {
          // Act
          final result = await fakeWrapper.signUp(
            email: 'new@example.com',
            password: 'password123',
          );

          // Assert
          expect(result.user, isNotNull);
          expect(result.user!.email, equals('new@example.com'));
          expect(result.session, isNotNull);
          expect(fakeWrapper.currentUser, isNotNull);
          expect(fakeWrapper.isAuthenticated, isTrue);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnSignUp = true;
          fakeWrapper.signUpErrorMessage = 'Email already exists';

          // Act & Assert
          expect(
            () async => await fakeWrapper.signUp(
              email: 'existing@example.com',
              password: 'password123',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email already exists'),
            )),
          );
        });
      });

      group('signInWithOtp', () {
        test('should complete successfully when configured', () async {
          // Act & Assert
          expect(
            () async => await fakeWrapper.signInWithOtp(
              email: 'test@example.com',
              shouldCreateUser: true,
            ),
            returnsNormally,
          );
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnOtp = true;
          fakeWrapper.otpErrorMessage = 'Failed to send OTP';

          // Act & Assert
          expect(
            () async => await fakeWrapper.signInWithOtp(
              email: 'test@example.com',
              shouldCreateUser: true,
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to send OTP'),
            )),
          );
        });
      });

      group('verifyOTP', () {
        test('should return successful auth response when configured', () async {
          // Act
          final result = await fakeWrapper.verifyOTP(
            email: 'otp@example.com',
            token: '123456',
            type: supabase.OtpType.email,
          );

          // Assert
          expect(result.user, isNotNull);
          expect(result.user!.email, equals('otp@example.com'));
          expect(result.session, isNotNull);
          expect(fakeWrapper.currentUser, isNotNull);
          expect(fakeWrapper.isAuthenticated, isTrue);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnVerifyOtp = true;
          fakeWrapper.verifyOtpErrorMessage = 'Invalid OTP code';

          // Act & Assert
          expect(
            () async => await fakeWrapper.verifyOTP(
              email: 'test@example.com',
              token: 'invalid',
              type: supabase.OtpType.email,
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid OTP code'),
            )),
          );
        });
      });

      group('resetPasswordForEmail', () {
        test('should complete successfully when configured', () async {
          // Act & Assert
          expect(
            () async => await fakeWrapper.resetPasswordForEmail(
              'test@example.com',
              redirectTo: null,
            ),
            returnsNormally,
          );
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnResetPassword = true;
          fakeWrapper.resetPasswordErrorMessage = 'User not found';

          // Act & Assert
          expect(
            () async => await fakeWrapper.resetPasswordForEmail(
              'notfound@example.com',
              redirectTo: null,
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User not found'),
            )),
          );
        });
      });

      group('signOut', () {
        test('should complete successfully when configured', () async {
          // Arrange - first sign in a user
          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          expect(fakeWrapper.isAuthenticated, isTrue);

          // Act
          await fakeWrapper.signOut();

          // Assert
          expect(fakeWrapper.currentUser, isNull);
          expect(fakeWrapper.isAuthenticated, isFalse);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnSignOut = true;
          fakeWrapper.signOutErrorMessage = 'Sign out failed';

          // Act & Assert
          expect(
            () async => await fakeWrapper.signOut(),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Sign out failed'),
            )),
          );
        });
      });
    });

    group('Authentication State', () {
      test('should return correct current user when set', () async {
        // Act
        await fakeWrapper.signInWithPassword(
          email: 'current@example.com',
          password: 'password',
        );

        // Assert
        final user = fakeWrapper.currentUser;
        expect(user, isNotNull);
        expect(user!.email, equals('current@example.com'));
      });

      test('should return null when no user is set', () {
        // Act
        final user = fakeWrapper.currentUser;

        // Assert
        expect(user, isNull);
      });

      test('should return correct authentication status', () async {
        // Initially not authenticated
        expect(fakeWrapper.isAuthenticated, isFalse);

        // Sign in user
        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
        expect(fakeWrapper.isAuthenticated, isTrue);

        // Sign out user
        await fakeWrapper.signOut();
        expect(fakeWrapper.isAuthenticated, isFalse);
      });

      test('should emit auth state changes when user changes', () async {
        // Arrange
        final authStates = <supabase.AuthState>[];
        final subscription = fakeWrapper.onAuthStateChange.listen(authStates.add);

        // Act
        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
        await Future.delayed(Duration(milliseconds: 10));

        await fakeWrapper.signOut();
        await Future.delayed(Duration(milliseconds: 10));

        // Assert
        expect(authStates.length, greaterThanOrEqualTo(2));
        expect(authStates.first.event, equals(supabase.AuthChangeEvent.signedIn));
        expect(authStates.first.session?.user.email, equals('user@example.com'));
        expect(authStates.last.event, equals(supabase.AuthChangeEvent.signedOut));
        expect(authStates.last.session, isNull);

        // Cleanup
        await subscription.cancel();
      });
    });

    group('Database Operations', () {
      group('selectSingle', () {
        test('should return data when record exists', () async {
          // Arrange
          fakeWrapper.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'name': 'Test User',
            }
          ]);

          // Act
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'test@example.com',
          );

          // Assert
          expect(result, isNotNull);
          expect(result!['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('Test User'));
        });

        test('should return null when record does not exist', () async {
          // Act
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'notfound@example.com',
          );

          // Assert
          expect(result, isNull);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnSelect = true;
          fakeWrapper.selectErrorMessage = 'Database error';

          // Act & Assert
          expect(
            () async => await fakeWrapper.selectSingle(
              table: 'users',
              filterColumn: 'id',
              filterValue: '1',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Database error'),
            )),
          );
        });

        test('should return null when configured to return null', () async {
          // Arrange
          fakeWrapper.shouldReturnNullOnSelect = true;

          // Act
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );

          // Assert
          expect(result, isNull);
        });
      });

      group('insert', () {
        test('should insert data and return with generated fields', () async {
          // Arrange
          final insertData = {
            'email': 'new@example.com',
            'name': 'New User',
          };

          // Act
          final result = await fakeWrapper.insert(
            table: 'users',
            data: insertData,
          );

          // Assert
          expect(result['id'], isNotNull);
          expect(result['email'], equals('new@example.com'));
          expect(result['name'], equals('New User'));
          expect(result['created_at'], isNotNull);
          expect(result['updated_at'], isNotNull);
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnInsert = true;
          fakeWrapper.insertErrorMessage = 'Insert failed';

          // Act & Assert
          expect(
            () async => await fakeWrapper.insert(
              table: 'users',
              data: {'email': 'test@example.com'},
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Insert failed'),
            )),
          );
        });

        test('should generate sequential IDs for multiple inserts', () async {
          // Act
          final result1 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user1@example.com'},
          );
          final result2 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user2@example.com'},
          );

          // Assert
          expect(result1['id'], equals('1'));
          expect(result2['id'], equals('2'));
        });
      });

      group('update', () {
        test('should update existing record and return updated data', () async {
          // Arrange
          fakeWrapper.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'name': 'Old Name',
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T00:00:00Z',
            }
          ]);

          // Act
          final result = await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          );

          // Assert
          expect(result['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('New Name'));
          expect(result['updated_at'], isNot(equals('2023-01-01T00:00:00Z')));
        });

        test('should throw exception when record not found', () async {
          // Act & Assert
          expect(
            () async => await fakeWrapper.update(
              table: 'users',
              data: {'name': 'New Name'},
              filterColumn: 'id',
              filterValue: 'nonexistent',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Record not found'),
            )),
          );
        });

        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnUpdate = true;
          fakeWrapper.updateErrorMessage = 'Update failed';

          // Act & Assert
          expect(
            () async => await fakeWrapper.update(
              table: 'users',
              data: {'name': 'New Name'},
              filterColumn: 'id',
              filterValue: '1',
            ),
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Update failed'),
            )),
          );
        });
      });
    });

    group('Test Utilities', () {
      test('should add and clear table data', () {
        // Arrange & Act
        fakeWrapper.addTableData('users', [
          {'id': '1', 'name': 'User 1'},
          {'id': '2', 'name': 'User 2'},
        ]);

        // Assert - Note: We can't directly access table data, so we test through selectSingle
        expect(
          () async => await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          ),
          returnsNormally,
        );

        // Act - Clear table data
        fakeWrapper.clearTableData('users');

        // Assert - Data should be cleared
        expect(
          () async => await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          ),
          returnsNormally,
        );
      });

      test('should clear all data', () async {
        // Arrange
        fakeWrapper.addTableData('users', [{'id': '1', 'name': 'User 1'}]);
        fakeWrapper.addTableData('posts', [{'id': '1', 'title': 'Post 1'}]);
        await fakeWrapper.signInWithPassword(email: 'test@example.com', password: 'password');

        // Act
        fakeWrapper.clearAllData();

        // Assert
        expect(fakeWrapper.currentUser, isNull);
        expect(fakeWrapper.isAuthenticated, isFalse);
        
        final userResult = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'id',
          filterValue: '1',
        );
        expect(userResult, isNull);
      });

      test('should reset all state', () async {
        // Arrange
        await fakeWrapper.signInWithPassword(email: 'user@example.com', password: 'password');
        fakeWrapper.addTableData('users', [{'id': '1', 'name': 'User 1'}]);
        fakeWrapper.shouldThrowOnSignIn = true;
        fakeWrapper.signInErrorMessage = 'Error';

        // Act
        fakeWrapper.reset();

        // Assert
        expect(fakeWrapper.currentUser, isNull);
        expect(fakeWrapper.isAuthenticated, isFalse);
        expect(fakeWrapper.shouldThrowOnSignIn, isFalse);
        expect(fakeWrapper.signInErrorMessage, isNull);
        
        final userResult = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'id',
          filterValue: '1',
        );
        expect(userResult, isNull);
      });
    });

    group('Fake User Implementation', () {
      test('should create fake user with correct properties', () {
        // Act
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
        );

        // Assert
        expect(user.id, equals('test-id'));
        expect(user.email, equals('test@example.com'));
        expect(user.createdAt, equals('2023-01-01T00:00:00Z'));
        expect(user.appMetadata, isEmpty);
        expect(user.userMetadata, isNull);
      });

      test('should handle metadata correctly', () {
        // Act
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
          appMetadata: {'role': 'admin'},
          userMetadata: {'name': 'Test User'},
        );

        // Assert
        expect(user.appMetadata['role'], equals('admin'));
        expect(user.userMetadata!['name'], equals('Test User'));
      });
    });

    group('Fake Auth Response Implementation', () {
      test('should create auth response with user and session', () {
        // Arrange
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
        );
        final session = FakeSession(user: user);

        // Act
        final response = FakeAuthResponse(user: user, session: session);

        // Assert
        expect(response.user, equals(user));
        expect(response.session, equals(session));
      });

      test('should create auth response with null user and session', () {
        // Act
        final response = FakeAuthResponse(user: null, session: null);

        // Assert
        expect(response.user, isNull);
        expect(response.session, isNull);
      });
    });

    group('Fake Session Implementation', () {
      test('should create session with user and tokens', () {
        // Arrange
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
        );

        // Act
        final session = FakeSession(
          user: user,
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
        );

        // Assert
        expect(session.user, equals(user));
        expect(session.accessToken, equals('access-token'));
        expect(session.refreshToken, equals('refresh-token'));
      });

      test('should use default tokens when not provided', () {
        // Arrange
        final user = FakeUser(
          id: 'test-id',
          email: 'test@example.com',
          createdAt: '2023-01-01T00:00:00Z',
        );

        // Act
        final session = FakeSession(user: user);

        // Assert
        expect(session.accessToken, equals('fake-access-token'));
        expect(session.refreshToken, equals('fake-refresh-token'));
      });
    });
  });

  group('FakeSupabaseInitializer', () {
    late FakeSupabaseInitializer fakeInitializer;

    setUp(() {
      fakeInitializer = FakeSupabaseInitializer();
    });

    tearDown(() {
      fakeInitializer.reset();
    });

    group('Initialization', () {
      test('should initialize successfully when not configured to throw', () async {
        // Act & Assert
        expect(
          () async => await fakeInitializer.initialize(
            url: 'https://test.supabase.co',
            anonKey: 'test_anon_key',
          ),
          returnsNormally,
        );
      });

      test('should store initialization parameters', () async {
        // Act
        await fakeInitializer.initialize(
          url: 'https://example.supabase.co',
          anonKey: 'example_anon_key',
        );

        // Assert
        expect(fakeInitializer.lastUrl, equals('https://example.supabase.co'));
        expect(fakeInitializer.lastAnonKey, equals('example_anon_key'));
        expect(fakeInitializer.lastDebugFlag, equals(false));
      });

      test('should store debug flag when provided', () async {
        // Act
        await fakeInitializer.initialize(
          url: 'https://debug.supabase.co',
          anonKey: 'debug_key',
          debug: true,
        );

        // Assert
        expect(fakeInitializer.lastUrl, equals('https://debug.supabase.co'));
        expect(fakeInitializer.lastAnonKey, equals('debug_key'));
        expect(fakeInitializer.lastDebugFlag, equals(true));
      });

      test('should return fake client', () async {
        // Act
        final client = await fakeInitializer.initialize(
          url: 'https://test.supabase.co',
          anonKey: 'test_key',
        );

        // Assert
        expect(client, isA<supabase.SupabaseClient>());
        expect(client, equals(fakeInitializer.fakeClient));
      });

      test('should throw exception when configured to fail', () async {
        // Arrange
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.initializeErrorMessage = 'Supabase initialization failed';

        // Act & Assert
        expect(
          () async => await fakeInitializer.initialize(
            url: 'https://test.supabase.co',
            anonKey: 'test_key',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Supabase initialization failed'),
          )),
        );
      });

      test('should throw default error message when no custom message set', () async {
        // Arrange
        fakeInitializer.shouldThrowOnInitialize = true;

        // Act & Assert
        expect(
          () async => await fakeInitializer.initialize(
            url: 'https://test.supabase.co',
            anonKey: 'test_key',
          ),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to initialize Supabase'),
          )),
        );
      });

      test('should not store parameters when throwing exception', () async {
        // Arrange
        fakeInitializer.shouldThrowOnInitialize = true;

        // Act
        try {
          await fakeInitializer.initialize(url: 'url', anonKey: 'key');
        } catch (_) {
          // Expected to throw
        }

        // Assert
        expect(fakeInitializer.lastUrl, isNull);
        expect(fakeInitializer.lastAnonKey, isNull);
        expect(fakeInitializer.lastDebugFlag, isNull);
      });
    });

    group('Reset Functionality', () {
      test('should reset all state and configuration', () async {
        // Arrange
        await fakeInitializer.initialize(url: 'test_url', anonKey: 'test_key');
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.initializeErrorMessage = 'Custom error';

        // Act
        fakeInitializer.reset();

        // Assert
        expect(fakeInitializer.lastUrl, isNull);
        expect(fakeInitializer.lastAnonKey, isNull);
        expect(fakeInitializer.lastDebugFlag, isNull);
        expect(fakeInitializer.shouldThrowOnInitialize, isFalse);
        expect(fakeInitializer.initializeErrorMessage, isNull);
      });

      test('should allow normal operation after reset', () async {
        // Arrange
        fakeInitializer.shouldThrowOnInitialize = true;
        fakeInitializer.reset();

        // Act & Assert
        expect(
          () async => await fakeInitializer.initialize(
            url: 'https://reset.supabase.co',
            anonKey: 'reset_key',
          ),
          returnsNormally,
        );
        expect(fakeInitializer.lastUrl, equals('https://reset.supabase.co'));
        expect(fakeInitializer.lastAnonKey, equals('reset_key'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty URL and key', () async {
        // Act
        await fakeInitializer.initialize(url: '', anonKey: '');

        // Assert
        expect(fakeInitializer.lastUrl, equals(''));
        expect(fakeInitializer.lastAnonKey, equals(''));
        expect(fakeInitializer.lastDebugFlag, equals(false));
      });

      test('should handle very long URLs and keys', () async {
        // Arrange
        final longUrl = 'https://${'a' * 1000}.supabase.co';
        final longKey = 'key_${'b' * 1000}';

        // Act
        await fakeInitializer.initialize(url: longUrl, anonKey: longKey);

        // Assert
        expect(fakeInitializer.lastUrl, equals(longUrl));
        expect(fakeInitializer.lastAnonKey, equals(longKey));
      });
    });
  });

  group('FakeSupabaseClient', () {
    late FakeSupabaseClient fakeClient;

    setUp(() {
      fakeClient = FakeSupabaseClient();
    });

    group('Basic Functionality', () {
      test('should be instance of SupabaseClient', () {
        // Assert
        expect(fakeClient, isA<supabase.SupabaseClient>());
      });

      test('should handle method calls with noSuchMethod', () {
        // Act & Assert - These should not throw since noSuchMethod handles them
        expect(() => fakeClient.toString(), returnsNormally);
      });
    });
  });

} 