import 'package:construculator/libraries/time/testing/clock_test_module.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_modular/flutter_modular.dart';
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
              isA<supabase.AuthException>().having(
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
              isA<supabase.AuthException>().having(
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
              isA<supabase.AuthException>().having(
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
                isA<supabase.AuthException>().having(
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
                isA<supabase.AuthException>().having(
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
            reason: 'User should be authenticated before sign out',
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
          reason: 'Should not be authenticated initially',
        );

        await fakeWrapper.signInWithPassword(
          email: 'user@example.com',
          password: 'password',
        );
        expect(
          fakeWrapper.isAuthenticated,
          isTrue,
          reason: 'Should be authenticated after sign-in',
        );

        await fakeWrapper.signOut();
        expect(
          fakeWrapper.isAuthenticated,
          isFalse,
          reason: 'Should not be authenticated after sign-out',
        );
      });

      test('onAuthStateChange emits events for sign-in and sign-out', () async {
        final authStateStream = fakeWrapper.onAuthStateChange;
        expectLater(
          authStateStream,
          emitsInOrder([
            predicate<supabase.AuthState>((state) {
              return state.event == supabase.AuthChangeEvent.signedIn &&
                  state.session!.user.email == 'user@example.com';
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
              'Simulating auth stream error after dispose should throw StateError because the controller is closed.',
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
      group('select', () {
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
        test(
          'selectProfessionalRoles returns roles list of professional roles',
          () async {
            fakeWrapper.addTableData('professional_roles', [
              {'id': '1', 'name': 'Test Role'},
            ]);

            final result = await fakeWrapper.selectAllProfessionalRoles();
            expect(result, isNotNull);
            expect(result.length, equals(1));
            expect(result[0]['id'], equals('1'));
            expect(result[0]['name'], equals('Test Role'));
          },
        );
        test(
          'selectProfessionalRoles throws exception when configured to fail',
          () async {
            fakeWrapper.shouldThrowOnSelect = true;
            fakeWrapper.authErrorCode = SupabaseAuthErrorCode.unknown;
            expect(
              () async => await fakeWrapper.selectAllProfessionalRoles(),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Select failed'),
                ),
              ),
            );
          },
        );
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
            reason: 'updated_at should change after update',
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
              reason: 'Default appMetadata should be empty',
            );
            expect(
              user.userMetadata,
              isNull,
              reason: 'Default userMetadata should be null',
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
              reason: 'Should use default access token',
            );
            expect(
              session.refreshToken,
              equals('fake-refresh-token'),
              reason: 'Should use default refresh token',
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
            reason: 'User 1 should be found after addTableData',
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
            reason: 'User 1 should be null after clearTableData',
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
            reason: 'Current user should be null after clearAllData',
          );
          expect(
            fakeWrapper.isAuthenticated,
            isFalse,
            reason: 'Should not be authenticated after clearAllData',
          );

          final userResult = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(userResult, isNull, reason: 'User data should be cleared');

          final postResult = await fakeWrapper.selectSingle(
            table: 'posts',
            filterColumn: 'id',
            filterValue: 'p1',
          );
          expect(postResult, isNull, reason: 'Post data should be cleared');
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
            reason: 'Initially, method calls should be empty.',
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
            reason: 'Initially, calls for signInWithPassword should be empty.',
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
            reason: 'Should have 3 signInWithPassword calls.',
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
            reason: 'Calls for a non-existent method should be empty.',
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
  List<Module> get imports => [ClockTestModule()];
  @override
  void binds(Injector i) {
    i.add<SupabaseWrapper>(() => FakeSupabaseWrapper(clock: i()));
  }
}
