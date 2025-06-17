<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:flutter_modular/flutter_modular.dart';
=======
import 'package:construculator/libraries/supabase/testing/fake_supabase_client.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_initializer.dart';
>>>>>>> 5777a70 (Fix restack errors)
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
<<<<<<< HEAD
  late FakeSupabaseWrapper fakeWrapper;

  setUp(() {
    Modular.init(_TestAppModule());
    fakeWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
  });

  tearDown(() {
    Modular.destroy();
  });
  group('FakeSupabaseWrapper', () {
    group('FakeSupabaseWrapper Authentication Methods', () {
      group('signInWithPassword', () {
        test(
          'returns success with user when configured for successful sign-in',
          () async {
            final result = await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            );

            expect(result.user, isNotNull);
            expect(result.user!.email, equals('test@example.com'));
            expect(result.session, isNotNull);
            expect(fakeWrapper.currentUser, isNotNull);
            expect(fakeWrapper.isAuthenticated, isTrue);
          },
        );

        test('throws exception when configured to fail sign-in', () async {
          fakeWrapper.shouldThrowOnSignIn = true;
          fakeWrapper.signInErrorMessage = 'Invalid credentials';

=======
  group('FakeSupabaseWrapper', () {
=======
=======
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
>>>>>>> f0238ef (Group tests)
=======
import 'package:construculator/libraries/supabase/testing/supabase_test_module.dart';
=======
>>>>>>> 77c4663 (Refactor to support new types)
import 'package:flutter_modular/flutter_modular.dart';
>>>>>>> dba60ba (Refactor: use app defined exceptions)
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  late FakeSupabaseWrapper fakeWrapper;

  setUp(() {
    Modular.init(_TestAppModule());
    fakeWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
  });

  tearDown(() {
    Modular.destroy();
  });
  group('FakeSupabaseWrapper', () {
    group('FakeSupabaseWrapper Authentication Methods', () {
      group('signInWithPassword', () {
        test(
          'returns success with user when configured for successful sign-in',
          () async {
            final result = await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            );

            expect(result.user, isNotNull);
            expect(result.user!.email, equals('test@example.com'));
            expect(result.session, isNotNull);
            expect(fakeWrapper.currentUser, isNotNull);
            expect(fakeWrapper.isAuthenticated, isTrue);
          },
        );

        test('throws exception when configured to fail sign-in', () async {
          fakeWrapper.shouldThrowOnSignIn = true;
          fakeWrapper.signInErrorMessage = 'Invalid credentials';

          expect(
            () async => await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'wrong-password',
            ),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Invalid credentials'),
              ),
            ),
          );
        });

        test(
          'returns null user when configured for null user on sign-in',
          () async {
            fakeWrapper.shouldReturnNullUser = true;

            final result = await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            );

            expect(result.user, isNull);
            expect(result.session, isNull);
          },
        );
      });

      group('signUp', () {
        test('returns success with new user on successful sign-up', () async {
          final result = await fakeWrapper.signUp(
            email: 'new@example.com',
            password: 'password123',
          );

          expect(result.user, isNotNull);
          expect(result.user!.email, equals('new@example.com'));
          expect(result.session, isNotNull);
          expect(fakeWrapper.currentUser, isNotNull);
          expect(fakeWrapper.isAuthenticated, isTrue);
        });

        test('throws exception when configured to fail sign-up', () async {
          fakeWrapper.shouldThrowOnSignUp = true;
          fakeWrapper.signUpErrorMessage = 'Email already exists';

          expect(
            () async => await fakeWrapper.signUp(
              email: 'existing@example.com',
              password: 'password123',
            ),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Email already exists'),
              ),
            ),
          );
        });
      });

      group('signInWithOtp', () {
        test(
          'completes successfully when configured for OTP sign-in',
          () async {
            expect(
              () async => await fakeWrapper.signInWithOtp(
                email: 'test@example.com',
                shouldCreateUser: true,
              ),
              returnsNormally,
            );
          },
        );

        test('throws exception when configured to fail OTP sign-in', () async {
          fakeWrapper.shouldThrowOnOtp = true;
          fakeWrapper.otpErrorMessage = 'Failed to send OTP';

          expect(
            () async => await fakeWrapper.signInWithOtp(
              email: 'test@example.com',
              shouldCreateUser: true,
            ),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Failed to send OTP'),
              ),
            ),
          );
        });
      });

      group('verifyOTP', () {
        test(
          'returns success with user on successful OTP verification',
          () async {
            final result = await fakeWrapper.verifyOTP(
              email: 'otp@example.com',
              token: '123456',
              type: supabase.OtpType.email,
            );

            expect(result.user, isNotNull);
            expect(result.user!.email, equals('otp@example.com'));
            expect(result.session, isNotNull);
            expect(fakeWrapper.currentUser, isNotNull);
            expect(fakeWrapper.isAuthenticated, isTrue);
          },
        );

        test(
          'throws exception when configured to fail OTP verification',
          () async {
            fakeWrapper.shouldThrowOnVerifyOtp = true;
            fakeWrapper.verifyOtpErrorMessage = 'Invalid OTP code';

            expect(
              () async => await fakeWrapper.verifyOTP(
                email: 'test@example.com',
                token: 'invalid',
                type: supabase.OtpType.email,
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Invalid OTP code'),
                ),
              ),
            );
          },
        );
      });

      group('resetPasswordForEmail', () {
        test(
          'completes successfully when configured for password reset',
          () async {
            expect(
              () async => await fakeWrapper.resetPasswordForEmail(
                'test@example.com',
                redirectTo: null,
              ),
              returnsNormally,
            );
          },
        );

        test(
          'throws exception when configured to fail password reset',
          () async {
            fakeWrapper.shouldThrowOnResetPassword = true;
            fakeWrapper.resetPasswordErrorMessage = 'User not found';

            expect(
              () async => await fakeWrapper.resetPasswordForEmail(
                'notfound@example.com',
                redirectTo: null,
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('User not found'),
                ),
              ),
            );
          },
        );
      });

      group('signOut', () {
        test('completes successfully and clears user session', () async {
          // Sign in a user first to establish a session
          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          expect(
            fakeWrapper.isAuthenticated,
            isTrue,
            reason: "User should be authenticated before sign out",
          );

          await fakeWrapper.signOut();

          expect(fakeWrapper.currentUser, isNull);
          expect(fakeWrapper.isAuthenticated, isFalse);
        });

        test('throws exception when configured to fail sign-out', () async {
          fakeWrapper.shouldThrowOnSignOut = true;
          fakeWrapper.signOutErrorMessage = 'Sign out failed';

          expect(
            () async => await fakeWrapper.signOut(),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Sign out failed'),
              ),
            ),
          );
        });
      });
    });
    group('FakeSupabaseWrapper Authentication State', () {
      test('currentUser returns the currently signed-in user', () async {
        await fakeWrapper.signInWithPassword(
          email: 'current@example.com',
          password: 'password',
        );

        final user = fakeWrapper.currentUser;
        expect(user, isNotNull);
        expect(user!.email, equals('current@example.com'));
      });

      test('currentUser returns null when no user is signed in', () {
        final user = fakeWrapper.currentUser;
        expect(user, isNull);
      });

      test('isAuthenticated reflects the current sign-in status', () async {
        // Initially not authenticated
        expect(
          fakeWrapper.isAuthenticated,
          isFalse,
          reason: "Should not be authenticated initially",
        );

        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
        expect(
          fakeWrapper.isAuthenticated,
          isTrue,
          reason: "Should be authenticated after sign-in",
        );

        await fakeWrapper.signOut();
        expect(
          fakeWrapper.isAuthenticated,
          isFalse,
          reason: "Should not be authenticated after sign-out",
        );
      });

      test('onAuthStateChange emits events for sign-in and sign-out', () async {
        final authStateStream = fakeWrapper.onAuthStateChange;
        expectLater(
          authStateStream,
          emitsInOrder([
            predicate<supabase.AuthState>((state) {
              return state.event == supabase.AuthChangeEvent.signedIn &&
                  state.session?.user.email == 'user@example.com';
            }),
            predicate<supabase.AuthState>((state) {
              return state.event == supabase.AuthChangeEvent.signedOut &&
                  state.session == null;
            }),
          ]),
        );
        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );

        await fakeWrapper.signOut();
      });

      test('dispose closes the authStateController', () async {
        // Listen to the stream before disposing
        final subscription = fakeWrapper.onAuthStateChange.listen(
          (_) {},
          onError: (_) {},
        );

        fakeWrapper.dispose();

        // Attempting to add an event to a closed controller should throw a StateError
        expect(
          () => fakeWrapper.setAuthStreamError('This should fail'),
          throwsA(isA<StateError>()),
          reason:
              "Simulating auth stream error after dispose should throw StateError because the controller is closed.",
        );
        await subscription.cancel();
      });

      test(
        'setAuthStreamError emits an error on onAuthStateChange stream',
        () async {
          final expectedErrorMessage = 'Simulated auth stream error!';

          // Expect an error to be emitted
          expectLater(
            fakeWrapper.onAuthStateChange,
            emitsError(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains(expectedErrorMessage),
              ),
            ),
          );

          fakeWrapper.setAuthStreamError(expectedErrorMessage);
        },
      );

      test(
        'emitAuthStateError (alias) emits an error on onAuthStateChange stream',
        () async {
          final expectedErrorMessage = 'Alias simulated auth stream error!';

          // Expect an error to be emitted
          expectLater(
            fakeWrapper.onAuthStateChange,
            emitsError(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains(expectedErrorMessage),
              ),
            ),
          );

          fakeWrapper.emitAuthStateError(expectedErrorMessage);
        },
      );
    });

    group('FakeSupabaseWrapper Database Operations', () {
      group('selectSingle', () {
        test('returns data when a matching record exists', () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'email': 'test@example.com', 'name': 'Test User'},
          ]);

          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'test@example.com',
          );

          expect(result, isNotNull);
          expect(result!['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('Test User'));
        });

        test('returns null when no matching record exists', () async {
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'notfound@example.com',
          );
          expect(result, isNull);
        });

        test(
          'throws exception when configured to fail select operations',
          () async {
            fakeWrapper.shouldThrowOnSelect = true;
            fakeWrapper.selectErrorMessage = 'Database error';

            expect(
              () async => await fakeWrapper.selectSingle(
                table: 'users',
                filterColumn: 'id',
                filterValue: '1',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Database error'),
                ),
              ),
            );
          },
        );

        test('returns null when configured to return null on select', () async {
          fakeWrapper.shouldReturnNullOnSelect = true;

          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(result, isNull);
        });
      });

      group('insert', () {
        test(
          'adds data to table and returns it with generated fields',
          () async {
            final insertData = {'email': 'new@example.com', 'name': 'New User'};

            final result = await fakeWrapper.insert(
              table: 'users',
              data: insertData,
            );

            expect(result['id'], isNotNull);
            expect(result['email'], equals('new@example.com'));
            expect(result['name'], equals('New User'));
            expect(result['created_at'], isNotNull);
            expect(result['updated_at'], isNotNull);
          },
        );

        test(
          'throws exception when configured to fail insert operations',
          () async {
            fakeWrapper.shouldThrowOnInsert = true;
            fakeWrapper.insertErrorMessage = 'Insert failed';

            expect(
              () async => await fakeWrapper.insert(
                table: 'users',
                data: {'email': 'test@example.com'},
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Insert failed'),
                ),
              ),
            );
          },
        );

        test('generates sequential IDs for multiple inserts', () async {
          final result1 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user1@example.com'},
          );
          final result2 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user2@example.com'},
          );

          expect(result1['id'], equals('1'));
          expect(result2['id'], equals('2'));
        });
      });

      group('update', () {
        test('modifies existing record and returns updated data', () async {
          final initialTime = '2023-01-01T00:00:00Z';
          fakeWrapper.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'name': 'Old Name',
              'created_at': initialTime,
              'updated_at': initialTime,
            },
          ]);

          final result = await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          );

          expect(result['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('New Name'));
          expect(
            result['updated_at'],
            isNot(equals(initialTime)),
            reason: "updated_at should change after update",
          );
        });

        test(
          'throws exception when trying to update a non-existent record',
          () async {
            // No data in the table initially
            expect(
              () async => await fakeWrapper.update(
                table: 'users',
                data: {'name': 'New Name'},
                filterColumn: 'id',
                filterValue: 'nonexistent',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Record not found'),
                ),
              ),
            );
          },
        );

        test(
          'throws exception when configured to fail update operations',
          () async {
            fakeWrapper.shouldThrowOnUpdate = true;
            fakeWrapper.updateErrorMessage = 'Update failed';

            // Ensure a record exists to attempt to update
            fakeWrapper.addTableData('users', [
              {'id': '1', 'email': 'test@example.com', 'name': 'Old Name'},
            ]);

            expect(
              () async => await fakeWrapper.update(
                table: 'users',
                data: {'name': 'New Name'},
                filterColumn: 'id',
                filterValue: '1',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Update failed'),
                ),
              ),
            );
          },
        );
      });
    });
    group('FakeSupabaseWrapper Fake Implementations', () {
      group('FakeUser Implementation', () {
        test(
          'constructor sets id, email, and createdAt correctly, with empty/null metadata by default',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: '2023-01-01T00:00:00Z',
            );

            expect(user.id, equals('test-id'));
            expect(user.email, equals('test@example.com'));
            expect(user.createdAt, equals('2023-01-01T00:00:00Z'));
            expect(
              user.appMetadata,
              isEmpty,
              reason: "Default appMetadata should be empty",
            );
            expect(
              user.userMetadata,
              isNull,
              reason: "Default userMetadata should be null",
            );
          },
        );

        test(
          'constructor correctly assigns provided appMetadata and userMetadata',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: '2023-01-01T00:00:00Z',
              appMetadata: {'role': 'admin'},
              userMetadata: {'name': 'Test User'},
            );

            expect(user.appMetadata['role'], equals('admin'));
            expect(user.userMetadata!['name'], equals('Test User'));
          },
        );
      });

      group('FakeAuthResponse Implementation', () {
        test('constructor correctly assigns user and session', () {
          final user = FakeUser(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: 'now',
          );
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
          final user = FakeUser(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: 'now',
          );

          final session = FakeSession(
            user: user,
            accessToken: 'custom-access-token',
            refreshToken: 'custom-refresh-token',
          );

          expect(session.user, same(user));
          expect(session.accessToken, equals('custom-access-token'));
          expect(session.refreshToken, equals('custom-refresh-token'));
        });

        test(
          'constructor uses default tokens if specific ones are not provided',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: 'now',
            );
            final session = FakeSession(user: user);

            expect(session.user, same(user));
            expect(
              session.accessToken,
              equals('fake-access-token'),
              reason: "Should use default access token",
            );
            expect(
              session.refreshToken,
              equals('fake-refresh-token'),
              reason: "Should use default refresh token",
            );
          },
        );
      });
    });

    group('FakeSupabaseWrapper Test Utilities', () {
      test(
        'addTableData adds records and clearTableData removes them for a specific table',
        () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
            {'id': '2', 'name': 'User 2'},
          ]);

          // Note: We can't directly access table data, so we test through selectSingle.
          var user1 = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(
            user1,
            isNotNull,
            reason: "User 1 should be found after addTableData",
          );
          expect(user1!['name'], equals('User 1'));

          fakeWrapper.clearTableData('users');

          user1 = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(
            user1,
            isNull,
            reason: "User 1 should be null after clearTableData",
          );
        },
      );

<<<<<<< HEAD
  group('FakeSupabaseWrapper Test Utilities', () {
>>>>>>> 927a930 (Merge supabase tests)
    late FakeSupabaseWrapper fakeWrapper;
=======
      test(
        'clearAllData removes data from all tables and resets auth state',
        () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
          ]);
          fakeWrapper.addTableData('posts', [
            {'id': 'p1', 'title': 'Post 1'},
          ]);
          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
>>>>>>> dba60ba (Refactor: use app defined exceptions)

          fakeWrapper.clearAllData();

          expect(
            fakeWrapper.currentUser,
            isNull,
            reason: "Current user should be null after clearAllData",
          );
          expect(
            fakeWrapper.isAuthenticated,
            isFalse,
            reason: "Should not be authenticated after clearAllData",
          );

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
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
>>>>>>> 5777a70 (Fix restack errors)
          expect(
            () async => await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'wrong-password',
            ),
<<<<<<< HEAD
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Invalid credentials'),
              ),
            ),
          );
        });

        test(
          'returns null user when configured for null user on sign-in',
          () async {
            fakeWrapper.shouldReturnNullUser = true;

            final result = await fakeWrapper.signInWithPassword(
              email: 'test@example.com',
              password: 'password123',
            );

            expect(result.user, isNull);
            expect(result.session, isNull);
          },
        );
      });

      group('signUp', () {
        test('returns success with new user on successful sign-up', () async {
=======
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
>>>>>>> 5777a70 (Fix restack errors)
          final result = await fakeWrapper.signUp(
            email: 'new@example.com',
            password: 'password123',
          );

<<<<<<< HEAD
=======
          // Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(result.user, isNotNull);
          expect(result.user!.email, equals('new@example.com'));
          expect(result.session, isNotNull);
          expect(fakeWrapper.currentUser, isNotNull);
          expect(fakeWrapper.isAuthenticated, isTrue);
        });

<<<<<<< HEAD
        test('throws exception when configured to fail sign-up', () async {
          fakeWrapper.shouldThrowOnSignUp = true;
          fakeWrapper.signUpErrorMessage = 'Email already exists';

=======
        test('should throw exception when configured to fail', () async {
          // Arrange
          fakeWrapper.shouldThrowOnSignUp = true;
          fakeWrapper.signUpErrorMessage = 'Email already exists';

          // Act & Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(
            () async => await fakeWrapper.signUp(
              email: 'existing@example.com',
              password: 'password123',
            ),
<<<<<<< HEAD
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Email already exists'),
              ),
            ),
=======
            throwsA(isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email already exists'),
            )),
>>>>>>> 5777a70 (Fix restack errors)
          );
        });
      });

      group('signInWithOtp', () {
<<<<<<< HEAD
        test(
          'completes successfully when configured for OTP sign-in',
          () async {
            expect(
              () async => await fakeWrapper.signInWithOtp(
                email: 'test@example.com',
                shouldCreateUser: true,
              ),
              returnsNormally,
            );
          },
        );

        test('throws exception when configured to fail OTP sign-in', () async {
          fakeWrapper.shouldThrowOnOtp = true;
          fakeWrapper.otpErrorMessage = 'Failed to send OTP';

=======
        test('should complete successfully when configured', () async {
          // Act & Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(
            () async => await fakeWrapper.signInWithOtp(
              email: 'test@example.com',
              shouldCreateUser: true,
            ),
<<<<<<< HEAD
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Failed to send OTP'),
              ),
            ),
=======
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
>>>>>>> 5777a70 (Fix restack errors)
          );
        });
      });

      group('verifyOTP', () {
<<<<<<< HEAD
        test(
          'returns success with user on successful OTP verification',
          () async {
            final result = await fakeWrapper.verifyOTP(
              email: 'otp@example.com',
              token: '123456',
              type: supabase.OtpType.email,
            );

            expect(result.user, isNotNull);
            expect(result.user!.email, equals('otp@example.com'));
            expect(result.session, isNotNull);
            expect(fakeWrapper.currentUser, isNotNull);
            expect(fakeWrapper.isAuthenticated, isTrue);
          },
        );

        test(
          'throws exception when configured to fail OTP verification',
          () async {
            fakeWrapper.shouldThrowOnVerifyOtp = true;
            fakeWrapper.verifyOtpErrorMessage = 'Invalid OTP code';

            expect(
              () async => await fakeWrapper.verifyOTP(
                email: 'test@example.com',
                token: 'invalid',
                type: supabase.OtpType.email,
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Invalid OTP code'),
                ),
              ),
            );
          },
        );
      });

      group('resetPasswordForEmail', () {
        test(
          'completes successfully when configured for password reset',
          () async {
            expect(
              () async => await fakeWrapper.resetPasswordForEmail(
                'test@example.com',
                redirectTo: null,
              ),
              returnsNormally,
            );
          },
        );

        test(
          'throws exception when configured to fail password reset',
          () async {
            fakeWrapper.shouldThrowOnResetPassword = true;
            fakeWrapper.resetPasswordErrorMessage = 'User not found';

            expect(
              () async => await fakeWrapper.resetPasswordForEmail(
                'notfound@example.com',
                redirectTo: null,
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('User not found'),
                ),
              ),
            );
          },
        );
      });

      group('signOut', () {
        test('completes successfully and clears user session', () async {
          // Sign in a user first to establish a session
=======
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
>>>>>>> 5777a70 (Fix restack errors)
          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
<<<<<<< HEAD
          expect(
            fakeWrapper.isAuthenticated,
            isTrue,
            reason: "User should be authenticated before sign out",
          );

          await fakeWrapper.signOut();

=======
          expect(fakeWrapper.isAuthenticated, isTrue);

          // Act
          await fakeWrapper.signOut();

          // Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(fakeWrapper.currentUser, isNull);
          expect(fakeWrapper.isAuthenticated, isFalse);
        });

<<<<<<< HEAD
        test('throws exception when configured to fail sign-out', () async {
          fakeWrapper.shouldThrowOnSignOut = true;
          fakeWrapper.signOutErrorMessage = 'Sign out failed';

          expect(
            () async => await fakeWrapper.signOut(),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('Sign out failed'),
              ),
            ),
=======
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
>>>>>>> 5777a70 (Fix restack errors)
          );
        });
      });
    });
<<<<<<< HEAD
    group('FakeSupabaseWrapper Authentication State', () {
      test('currentUser returns the currently signed-in user', () async {
=======

    group('Authentication State', () {
      test('should return correct current user when set', () async {
        // Act
>>>>>>> 5777a70 (Fix restack errors)
        await fakeWrapper.signInWithPassword(
          email: 'current@example.com',
          password: 'password',
        );

<<<<<<< HEAD
=======
        // Assert
>>>>>>> 5777a70 (Fix restack errors)
        final user = fakeWrapper.currentUser;
        expect(user, isNotNull);
        expect(user!.email, equals('current@example.com'));
      });

<<<<<<< HEAD
      test('currentUser returns null when no user is signed in', () {
        final user = fakeWrapper.currentUser;
        expect(user, isNull);
      });

      test('isAuthenticated reflects the current sign-in status', () async {
        // Initially not authenticated
        expect(
          fakeWrapper.isAuthenticated,
          isFalse,
          reason: "Should not be authenticated initially",
        );

=======
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
>>>>>>> 5777a70 (Fix restack errors)
        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
<<<<<<< HEAD
        expect(
          fakeWrapper.isAuthenticated,
          isTrue,
          reason: "Should be authenticated after sign-in",
        );

        await fakeWrapper.signOut();
        expect(
          fakeWrapper.isAuthenticated,
          isFalse,
          reason: "Should not be authenticated after sign-out",
        );
      });

      test('onAuthStateChange emits events for sign-in and sign-out', () async {
        final authStateStream = fakeWrapper.onAuthStateChange;
        expectLater(
          authStateStream,
          emitsInOrder([
            predicate<supabase.AuthState>((state) {
              return state.event == supabase.AuthChangeEvent.signedIn &&
                  state.session?.user.email == 'user@example.com';
            }),
            predicate<supabase.AuthState>((state) {
              return state.event == supabase.AuthChangeEvent.signedOut &&
                  state.session == null;
            }),
          ]),
        );
=======
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
>>>>>>> 5777a70 (Fix restack errors)
        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
<<<<<<< HEAD

        await fakeWrapper.signOut();
      });

      test('dispose closes the authStateController', () async {
        // Listen to the stream before disposing
        final subscription = fakeWrapper.onAuthStateChange.listen(
          (_) {},
          onError: (_) {},
        );

        fakeWrapper.dispose();

        // Attempting to add an event to a closed controller should throw a StateError
        expect(
          () => fakeWrapper.setAuthStreamError('This should fail'),
          throwsA(isA<StateError>()),
          reason:
              "Simulating auth stream error after dispose should throw StateError because the controller is closed.",
        );
        await subscription.cancel();
      });

      test(
        'setAuthStreamError emits an error on onAuthStateChange stream',
        () async {
          final expectedErrorMessage = 'Simulated auth stream error!';

          // Expect an error to be emitted
          expectLater(
            fakeWrapper.onAuthStateChange,
            emitsError(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains(expectedErrorMessage),
              ),
            ),
          );

          fakeWrapper.setAuthStreamError(expectedErrorMessage);
        },
      );

      test(
        'emitAuthStateError (alias) emits an error on onAuthStateChange stream',
        () async {
          final expectedErrorMessage = 'Alias simulated auth stream error!';

          // Expect an error to be emitted
          expectLater(
            fakeWrapper.onAuthStateChange,
            emitsError(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains(expectedErrorMessage),
              ),
            ),
          );

          fakeWrapper.emitAuthStateError(expectedErrorMessage);
        },
      );
    });

    group('FakeSupabaseWrapper Database Operations', () {
      group('selectSingle', () {
        test('returns data when a matching record exists', () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'email': 'test@example.com', 'name': 'Test User'},
          ]);

=======
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
>>>>>>> 5777a70 (Fix restack errors)
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'test@example.com',
          );

<<<<<<< HEAD
=======
          // Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(result, isNotNull);
          expect(result!['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('Test User'));
        });

<<<<<<< HEAD
        test('returns null when no matching record exists', () async {
=======
        test('should return null when record does not exist', () async {
          // Act
>>>>>>> 5777a70 (Fix restack errors)
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'email',
            filterValue: 'notfound@example.com',
          );
<<<<<<< HEAD
          expect(result, isNull);
        });

        test(
          'throws exception when configured to fail select operations',
          () async {
            fakeWrapper.shouldThrowOnSelect = true;
            fakeWrapper.selectErrorMessage = 'Database error';

            expect(
              () async => await fakeWrapper.selectSingle(
                table: 'users',
                filterColumn: 'id',
                filterValue: '1',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Database error'),
                ),
              ),
            );
          },
        );

        test('returns null when configured to return null on select', () async {
          fakeWrapper.shouldReturnNullOnSelect = true;

=======

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
>>>>>>> 5777a70 (Fix restack errors)
          final result = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
<<<<<<< HEAD
=======

          // Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(result, isNull);
        });
      });

      group('insert', () {
<<<<<<< HEAD
        test(
          'adds data to table and returns it with generated fields',
          () async {
            final insertData = {'email': 'new@example.com', 'name': 'New User'};

            final result = await fakeWrapper.insert(
              table: 'users',
              data: insertData,
            );

            expect(result['id'], isNotNull);
            expect(result['email'], equals('new@example.com'));
            expect(result['name'], equals('New User'));
            expect(result['created_at'], isNotNull);
            expect(result['updated_at'], isNotNull);
          },
        );

        test(
          'throws exception when configured to fail insert operations',
          () async {
            fakeWrapper.shouldThrowOnInsert = true;
            fakeWrapper.insertErrorMessage = 'Insert failed';

            expect(
              () async => await fakeWrapper.insert(
                table: 'users',
                data: {'email': 'test@example.com'},
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Insert failed'),
                ),
              ),
            );
          },
        );

        test('generates sequential IDs for multiple inserts', () async {
=======
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
>>>>>>> 5777a70 (Fix restack errors)
          final result1 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user1@example.com'},
          );
          final result2 = await fakeWrapper.insert(
            table: 'users',
            data: {'email': 'user2@example.com'},
          );

<<<<<<< HEAD
=======
          // Assert
>>>>>>> 5777a70 (Fix restack errors)
          expect(result1['id'], equals('1'));
          expect(result2['id'], equals('2'));
        });
      });

      group('update', () {
<<<<<<< HEAD
        test('modifies existing record and returns updated data', () async {
          final initialTime = '2023-01-01T00:00:00Z';
=======
        test('should update existing record and return updated data', () async {
          // Arrange
>>>>>>> 5777a70 (Fix restack errors)
          fakeWrapper.addTableData('users', [
            {
              'id': '1',
              'email': 'test@example.com',
              'name': 'Old Name',
<<<<<<< HEAD
              'created_at': initialTime,
              'updated_at': initialTime,
            },
          ]);

=======
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T00:00:00Z',
            }
          ]);

          // Act
>>>>>>> 5777a70 (Fix restack errors)
          final result = await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          );

<<<<<<< HEAD
          expect(result['id'], equals('1'));
          expect(result['email'], equals('test@example.com'));
          expect(result['name'], equals('New Name'));
          expect(
            result['updated_at'],
            isNot(equals(initialTime)),
            reason: "updated_at should change after update",
          );
        });

        test(
          'throws exception when trying to update a non-existent record',
          () async {
            // No data in the table initially
            expect(
              () async => await fakeWrapper.update(
                table: 'users',
                data: {'name': 'New Name'},
                filterColumn: 'id',
                filterValue: 'nonexistent',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Record not found'),
                ),
              ),
            );
          },
        );

        test(
          'throws exception when configured to fail update operations',
          () async {
            fakeWrapper.shouldThrowOnUpdate = true;
            fakeWrapper.updateErrorMessage = 'Update failed';

            // Ensure a record exists to attempt to update
            fakeWrapper.addTableData('users', [
              {'id': '1', 'email': 'test@example.com', 'name': 'Old Name'},
            ]);

            expect(
              () async => await fakeWrapper.update(
                table: 'users',
                data: {'name': 'New Name'},
                filterColumn: 'id',
                filterValue: '1',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Update failed'),
                ),
              ),
            );
          },
        );
      });
    });
    group('FakeSupabaseWrapper Fake Implementations', () {
      group('FakeUser Implementation', () {
        test(
          'constructor sets id, email, and createdAt correctly, with empty/null metadata by default',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: '2023-01-01T00:00:00Z',
            );

            expect(user.id, equals('test-id'));
            expect(user.email, equals('test@example.com'));
            expect(user.createdAt, equals('2023-01-01T00:00:00Z'));
            expect(
              user.appMetadata,
              isEmpty,
              reason: "Default appMetadata should be empty",
            );
            expect(
              user.userMetadata,
              isNull,
              reason: "Default userMetadata should be null",
            );
          },
        );

        test(
          'constructor correctly assigns provided appMetadata and userMetadata',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: '2023-01-01T00:00:00Z',
              appMetadata: {'role': 'admin'},
              userMetadata: {'name': 'Test User'},
            );

            expect(user.appMetadata['role'], equals('admin'));
            expect(user.userMetadata!['name'], equals('Test User'));
          },
        );
      });

      group('FakeAuthResponse Implementation', () {
        test('constructor correctly assigns user and session', () {
          final user = FakeUser(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: 'now',
          );
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
          final user = FakeUser(
            id: 'test-id',
            email: 'test@example.com',
            createdAt: 'now',
          );

          final session = FakeSession(
            user: user,
            accessToken: 'custom-access-token',
            refreshToken: 'custom-refresh-token',
          );

          expect(session.user, same(user));
          expect(session.accessToken, equals('custom-access-token'));
          expect(session.refreshToken, equals('custom-refresh-token'));
        });

        test(
          'constructor uses default tokens if specific ones are not provided',
          () {
            final user = FakeUser(
              id: 'test-id',
              email: 'test@example.com',
              createdAt: 'now',
            );
            final session = FakeSession(user: user);

            expect(session.user, same(user));
            expect(
              session.accessToken,
              equals('fake-access-token'),
              reason: "Should use default access token",
            );
            expect(
              session.refreshToken,
              equals('fake-refresh-token'),
              reason: "Should use default refresh token",
            );
          },
        );
      });
    });

    group('FakeSupabaseWrapper Test Utilities', () {
      test(
        'addTableData adds records and clearTableData removes them for a specific table',
        () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
            {'id': '2', 'name': 'User 2'},
          ]);

          // Note: We can't directly access table data, so we test through selectSingle.
          var user1 = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(
            user1,
            isNotNull,
            reason: "User 1 should be found after addTableData",
          );
          expect(user1!['name'], equals('User 1'));

          fakeWrapper.clearTableData('users');

          user1 = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(
            user1,
            isNull,
            reason: "User 1 should be null after clearTableData",
          );
        },
      );

      test(
        'clearAllData removes data from all tables and resets auth state',
        () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
          ]);
          fakeWrapper.addTableData('posts', [
            {'id': 'p1', 'title': 'Post 1'},
          ]);
          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );

          fakeWrapper.clearAllData();

          expect(
            fakeWrapper.currentUser,
            isNull,
            reason: "Current user should be null after clearAllData",
          );
          expect(
            fakeWrapper.isAuthenticated,
            isFalse,
            reason: "Should not be authenticated after clearAllData",
          );

=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)
          final userResult = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(userResult, isNull, reason: "User data should be cleared");
<<<<<<< HEAD

          final postResult = await fakeWrapper.selectSingle(
            table: 'posts',
            filterColumn: 'id',
            filterValue: 'p1',
          );
          expect(postResult, isNull, reason: "Post data should be cleared");
        },
      );
    });

    group('FakeSupabaseWrapper: Verifying Method Call Recording', () {
      test(
        'getMethodCalls returns empty list initially and all calls after operations',
        () async {
          expect(
            fakeWrapper.getMethodCalls(),
            isEmpty,
            reason: "Initially, method calls should be empty.",
          );

          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: 'any',
          );
          fakeWrapper.signOut();

          final calls = fakeWrapper.getMethodCalls();
          expect(calls, hasLength(3));
          expect(calls[0]['method'], equals('signInWithPassword'));
          expect(calls[1]['method'], equals('selectSingle'));
          expect(calls[2]['method'], equals('signOut'));
        },
      );

      test(
        'getLastMethodCall returns null initially and the last call after operations',
        () async {
          expect(fakeWrapper.getLastMethodCall(), isNull);

          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          var lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('signInWithPassword'));
          expect(lastCall['email'], equals('test@example.com'));

          await fakeWrapper.selectSingle(
            table: 'items',
            filterColumn: 'id',
            filterValue: '1',
          );
          lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('selectSingle'));
          expect(lastCall['table'], equals('items'));

          fakeWrapper.signOut();
          lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('signOut'));
          expect(lastCall['params'], isNull);
        },
      );

      test(
        'getMethodCallsFor returns empty list for uncalled methods and specific calls otherwise',
        () async {
          expect(
            fakeWrapper.getMethodCallsFor('signInWithPassword'),
            isEmpty,
            reason:
                "Initially, calls for 'signInWithPassword' should be empty.",
          );
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
          ]);
          await fakeWrapper.signInWithPassword(
            email: 'user1@example.com',
            password: 'password',
          );
          await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: 'any',
          );
          await fakeWrapper.signInWithPassword(
            email: 'user2@example.com',
            password: 'password',
          );
          await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          );
          await fakeWrapper.signInWithPassword(
            email: 'user3@example.com',
            password: 'password',
          );

          final signInCalls = fakeWrapper.getMethodCallsFor(
            'signInWithPassword',
          );
          expect(
            signInCalls,
            hasLength(3),
            reason: "Should have 3 'signInWithPassword' calls.",
          );
          expect(signInCalls[0]['email'], equals('user1@example.com'));
          expect(signInCalls[1]['email'], equals('user2@example.com'));
          expect(signInCalls[2]['email'], equals('user3@example.com'));

          final selectCalls = fakeWrapper.getMethodCallsFor('selectSingle');
          expect(
            selectCalls,
            hasLength(1),
            reason: "Should have 1 'selectSingle' call.",
          );
          expect(selectCalls[0]['table'], equals('users'));

          final updateCalls = fakeWrapper.getMethodCallsFor('update');
          expect(
            updateCalls,
            hasLength(1),
            reason: "Should have 1 'update' call.",
          );
          expect(updateCalls[0]['filterValue'], equals('1'));

          expect(
            fakeWrapper.getMethodCallsFor('nonExistentMethod'),
            isEmpty,
            reason: "Calls for a non-existent method should be empty.",
          );
        },
      );
      test('clearMethodCalls clears the method calls', () async {
        await fakeWrapper.signInWithPassword(
          email: 'test@example.com',
          password: 'password',
        );
        expect(fakeWrapper.getMethodCalls(), isNotEmpty);
        fakeWrapper.clearMethodCalls();
        expect(fakeWrapper.getMethodCalls(), isEmpty);
      });
<<<<<<< HEAD

      test('initialize throws exception when called', () async {
        expect(
          () async => await fakeWrapper.initialize(),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  void binds(Injector i) {
    i.add<SupabaseWrapper>(() => FakeSupabaseWrapper());
  }
}
=======
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
=======
    test(
      'addTableData adds records and clearTableData removes them for a specific table',
      () async {
>>>>>>> f0238ef (Group tests)
        fakeWrapper.addTableData('users', [
          {'id': '1', 'name': 'User 1'},
          {'id': '2', 'name': 'User 2'},
        ]);
<<<<<<< HEAD

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
>>>>>>> 5777a70 (Fix restack errors)
=======
    test('addTableData adds records and clearTableData removes them for a specific table', () async {
      fakeWrapper.addTableData('users', [
        {'id': '1', 'name': 'User 1'},
        {'id': '2', 'name': 'User 2'},
      ]);
=======
>>>>>>> f0238ef (Group tests)
=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)

          final postResult = await fakeWrapper.selectSingle(
            table: 'posts',
            filterColumn: 'id',
            filterValue: 'p1',
          );
          expect(postResult, isNull, reason: "Post data should be cleared");
        },
      );
    });
<<<<<<< HEAD
  });
<<<<<<< HEAD
} 
>>>>>>> 927a930 (Merge supabase tests)
=======

 });
}
>>>>>>> f0238ef (Group tests)
=======

    group('FakeSupabaseWrapper: Verifying Method Call Recording', () {
      test(
        'getMethodCalls returns empty list initially and all calls after operations',
        () async {
          expect(
            fakeWrapper.getMethodCalls(),
            isEmpty,
            reason: "Initially, method calls should be empty.",
          );

          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: 'any',
          );
          fakeWrapper.signOut();

          final calls = fakeWrapper.getMethodCalls();
          expect(calls, hasLength(3));
          expect(calls[0]['method'], equals('signInWithPassword'));
          expect(calls[1]['method'], equals('selectSingle'));
          expect(calls[2]['method'], equals('signOut'));
        },
      );

      test(
        'getLastMethodCall returns null initially and the last call after operations',
        () async {
          expect(fakeWrapper.getLastMethodCall(), isNull);

          await fakeWrapper.signInWithPassword(
            email: 'test@example.com',
            password: 'password',
          );
          var lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('signInWithPassword'));
          expect(lastCall['email'], equals('test@example.com'));

          await fakeWrapper.selectSingle(
            table: 'items',
            filterColumn: 'id',
            filterValue: '1',
          );
          lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('selectSingle'));
          expect(lastCall['table'], equals('items'));

          fakeWrapper.signOut();
          lastCall = fakeWrapper.getLastMethodCall();
          expect(lastCall, isNotNull);
          expect(lastCall!['method'], equals('signOut'));
          expect(lastCall['params'], isNull);
        },
      );

      test(
        'getMethodCallsFor returns empty list for uncalled methods and specific calls otherwise',
        () async {
          expect(
            fakeWrapper.getMethodCallsFor('signInWithPassword'),
            isEmpty,
            reason:
                "Initially, calls for 'signInWithPassword' should be empty.",
          );
          fakeWrapper.addTableData('users', [
            {'id': '1', 'name': 'User 1'},
          ]);
          await fakeWrapper.signInWithPassword(
            email: 'user1@example.com',
            password: 'password',
          );
          await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: 'any',
          );
          await fakeWrapper.signInWithPassword(
            email: 'user2@example.com',
            password: 'password',
          );
          await fakeWrapper.update(
            table: 'users',
            data: {'name': 'New Name'},
            filterColumn: 'id',
            filterValue: '1',
          );
          await fakeWrapper.signInWithPassword(
            email: 'user3@example.com',
            password: 'password',
          );

          final signInCalls = fakeWrapper.getMethodCallsFor(
            'signInWithPassword',
          );
          expect(
            signInCalls,
            hasLength(3),
            reason: "Should have 3 'signInWithPassword' calls.",
          );
          expect(signInCalls[0]['email'], equals('user1@example.com'));
          expect(signInCalls[1]['email'], equals('user2@example.com'));
          expect(signInCalls[2]['email'], equals('user3@example.com'));

          final selectCalls = fakeWrapper.getMethodCallsFor('selectSingle');
          expect(
            selectCalls,
            hasLength(1),
            reason: "Should have 1 'selectSingle' call.",
          );
          expect(selectCalls[0]['table'], equals('users'));

          final updateCalls = fakeWrapper.getMethodCallsFor('update');
          expect(
            updateCalls,
            hasLength(1),
            reason: "Should have 1 'update' call.",
          );
          expect(updateCalls[0]['filterValue'], equals('1'));

          expect(
            fakeWrapper.getMethodCallsFor('nonExistentMethod'),
            isEmpty,
            reason: "Calls for a non-existent method should be empty.",
          );
        },
      );
=======
>>>>>>> b0b9b8a (Fix restack errors)

      test('initialize throws exception when called', () async {
        expect(
          () async => await fakeWrapper.initialize(),
          throwsA(isA<UnimplementedError>()),
        );
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  void binds(Injector i) {
    i.add<SupabaseWrapper>(() => FakeSupabaseWrapper());
  }
}
>>>>>>> dba60ba (Refactor: use app defined exceptions)
