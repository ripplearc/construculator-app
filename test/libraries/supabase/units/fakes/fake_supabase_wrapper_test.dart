import 'dart:async';

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

      group('delete', () {
        test('removes record from table', () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'email': 'test@example.com', 'name': 'Test User'},
            {'id': '2', 'email': 'other@example.com', 'name': 'Other User'},
          ]);

          await fakeWrapper.delete(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );

          final deletedUser = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );
          expect(deletedUser, isNull);

          final remainingUser = await fakeWrapper.selectSingle(
            table: 'users',
            filterColumn: 'id',
            filterValue: '2',
          );
          expect(remainingUser, isNotNull);
          expect(remainingUser!['email'], equals('other@example.com'));
        });

        test(
          'throws exception when configured to fail delete operations',
          () async {
            fakeWrapper.shouldThrowOnDelete = true;
            fakeWrapper.deleteErrorMessage = 'Delete failed';

            expect(
              () async => await fakeWrapper.delete(
                table: 'users',
                filterColumn: 'id',
                filterValue: '1',
              ),
              throwsA(
                isA<ServerException>().having(
                  (e) => e.toString(),
                  'message',
                  contains('Delete failed'),
                ),
              ),
            );
          },
        );

        test('handles delayed operations', () async {
          fakeWrapper.addTableData('users', [
            {'id': '1', 'email': 'test@example.com', 'name': 'Test User'},
          ]);
          fakeWrapper.shouldDelayOperations = true;
          fakeWrapper.completer = Completer();

          final future = fakeWrapper.delete(
            table: 'users',
            filterColumn: 'id',
            filterValue: '1',
          );

          expect(fakeWrapper.getMethodCallsFor('delete'), isEmpty);

          fakeWrapper.completer!.complete();
          await future;

          expect(fakeWrapper.getMethodCallsFor('delete'), hasLength(1));
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

      group('rpc', () {
        test('returns configured response for successful RPC call', () async {
          fakeWrapper.setRpcResponse('check_email_exists', true);

          final result = await fakeWrapper.rpc<bool>(
            'check_email_exists',
            params: {'email_input': 'test@example.com'},
          );

          expect(result, isTrue);
          expect(fakeWrapper.getMethodCallsFor('rpc'), hasLength(1));
          final rpcCall = fakeWrapper.getMethodCallsFor('rpc').first;
          expect(rpcCall['functionName'], equals('check_email_exists'));
          expect(
            rpcCall['params'],
            equals({'email_input': 'test@example.com'}),
          );
        });

        test('returns false for configured false response', () async {
          fakeWrapper.setRpcResponse('check_email_exists', false);

          final result = await fakeWrapper.rpc<bool>(
            'check_email_exists',
            params: {'email_input': 'unknown@example.com'},
          );

          expect(result, isFalse);
        });

        test('supports different return types (int)', () async {
          fakeWrapper.setRpcResponse('get_user_count', 42);

          final result = await fakeWrapper.rpc<int>('get_user_count');

          expect(result, equals(42));
        });

        test('supports different return types (String)', () async {
          fakeWrapper.setRpcResponse('get_user_role', 'admin');

          final result = await fakeWrapper.rpc<String>(
            'get_user_role',
            params: {'user_id': '123'},
          );

          expect(result, equals('admin'));
        });

        test('supports different return types (Map)', () async {
          final expectedData = {'id': '1', 'name': 'Test User'};
          fakeWrapper.setRpcResponse('get_user_data', expectedData);

          final result = await fakeWrapper.rpc<Map<String, dynamic>>(
            'get_user_data',
            params: {'user_id': '1'},
          );

          expect(result, equals(expectedData));
        });

        test('throws exception when configured to fail', () async {
          fakeWrapper.shouldThrowOnRpc = true;
          fakeWrapper.rpcErrorMessage = 'RPC call failed';

          expect(
            () async => await fakeWrapper.rpc<bool>(
              'check_email_exists',
              params: {'email_input': 'test@example.com'},
            ),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('RPC call failed'),
              ),
            ),
          );
        });

        test('throws ServerException when no response is configured', () async {
          expect(
            () async => await fakeWrapper.rpc<bool>(
              'unconfigured_function',
              params: {'param': 'value'},
            ),
            throwsA(
              isA<ServerException>().having(
                (e) => e.toString(),
                'message',
                contains('No RPC response configured for function'),
              ),
            ),
          );
        });

        test('throws PostgrestException when configured', () async {
          fakeWrapper.shouldThrowOnRpc = true;
          fakeWrapper.rpcErrorMessage = 'Permission denied';
          fakeWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
          fakeWrapper.postgrestErrorCode = PostgresErrorCode.unknownError;

          expect(
            () async => await fakeWrapper.rpc<bool>(
              'check_email_exists',
              params: {'email_input': 'test@example.com'},
            ),
            throwsA(
              isA<supabase.PostgrestException>().having(
                (e) => e.message,
                'message',
                contains('Permission denied'),
              ),
            ),
          );
        });

        test('records method calls correctly', () async {
          fakeWrapper.setRpcResponse('function1', 'result1');
          fakeWrapper.setRpcResponse('function2', 'result2');

          await fakeWrapper.rpc<String>(
            'function1',
            params: {'param1': 'value1'},
          );
          await fakeWrapper.rpc<String>(
            'function2',
            params: {'param2': 'value2'},
          );

          final rpcCalls = fakeWrapper.getMethodCallsFor('rpc');
          expect(rpcCalls, hasLength(2));
          expect(rpcCalls[0]['functionName'], equals('function1'));
          expect(rpcCalls[0]['params'], equals({'param1': 'value1'}));
          expect(rpcCalls[1]['functionName'], equals('function2'));
          expect(rpcCalls[1]['params'], equals({'param2': 'value2'}));
        });

        test('clearRpcResponses removes all configured responses', () async {
          fakeWrapper.setRpcResponse('function1', true);
          fakeWrapper.setRpcResponse('function2', false);

          final result1 = await fakeWrapper.rpc<bool>('function1');
          expect(result1, isTrue);

          fakeWrapper.clearRpcResponses();

          expect(
            () async => await fakeWrapper.rpc<bool>('function1'),
            throwsA(isA<ServerException>()),
          );
          expect(
            () async => await fakeWrapper.rpc<bool>('function2'),
            throwsA(isA<ServerException>()),
          );
        });

        test('handles delayed operations', () async {
          fakeWrapper.setRpcResponse('delayed_function', true);
          fakeWrapper.shouldDelayOperations = true;
          fakeWrapper.completer = Completer();

          final future = fakeWrapper.rpc<bool>(
            'delayed_function',
            params: {'test': 'value'},
          );

          // Method call should not be recorded yet
          expect(fakeWrapper.getMethodCallsFor('rpc'), isEmpty);

          // Complete the delayed operation
          fakeWrapper.completer!.complete();
          final result = await future;

          expect(result, isTrue);
          expect(fakeWrapper.getMethodCallsFor('rpc'), hasLength(1));
        });

        test('supports RPC calls without parameters', () async {
          fakeWrapper.setRpcResponse('get_server_time', '2023-01-01T00:00:00Z');

          final result = await fakeWrapper.rpc<String>('get_server_time');

          expect(result, equals('2023-01-01T00:00:00Z'));
          final rpcCall = fakeWrapper.getMethodCallsFor('rpc').first;
          expect(rpcCall['params'], isNull);
        });

        test('allows multiple calls to same function', () async {
          fakeWrapper.setRpcResponse('check_email_exists', true);

          final result1 = await fakeWrapper.rpc<bool>(
            'check_email_exists',
            params: {'email_input': 'user1@example.com'},
          );
          final result2 = await fakeWrapper.rpc<bool>(
            'check_email_exists',
            params: {'email_input': 'user2@example.com'},
          );

          expect(result1, isTrue);
          expect(result2, isTrue);
          expect(fakeWrapper.getMethodCallsFor('rpc'), hasLength(2));
        });
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

    group('reset', () {
      test('clears all configurations and data', () async {
        fakeWrapper.addTableData('users', [
          {'id': '1', 'name': 'Test User'},
        ]);
        await fakeWrapper.signInWithPassword(
          email: 'test@example.com',
          password: 'password',
        );
        fakeWrapper.shouldThrowOnSignIn = true;
        fakeWrapper.shouldThrowOnSignUp = true;
        fakeWrapper.shouldThrowOnOtp = true;
        fakeWrapper.shouldThrowOnVerifyOtp = true;
        fakeWrapper.shouldThrowOnResetPassword = true;
        fakeWrapper.shouldThrowOnSignOut = true;
        fakeWrapper.shouldThrowOnSelect = true;
        fakeWrapper.shouldThrowOnInsert = true;
        fakeWrapper.shouldThrowOnUpdate = true;
        fakeWrapper.shouldThrowOnSelectMultiple = true;
        fakeWrapper.shouldThrowOnDelete = true;
        fakeWrapper.shouldThrowOnRpc = true;
        fakeWrapper.signInErrorMessage = 'Sign in failed';
        fakeWrapper.signUpErrorMessage = 'Sign up failed';
        fakeWrapper.otpErrorMessage = 'OTP failed';
        fakeWrapper.verifyOtpErrorMessage = 'Verify OTP failed';
        fakeWrapper.resetPasswordErrorMessage = 'Reset password failed';
        fakeWrapper.signOutErrorMessage = 'Sign out failed';
        fakeWrapper.selectErrorMessage = 'Select failed';
        fakeWrapper.insertErrorMessage = 'Insert failed';
        fakeWrapper.updateErrorMessage = 'Update failed';
        fakeWrapper.deleteErrorMessage = 'Delete failed';
        fakeWrapper.rpcErrorMessage = 'RPC failed';
        fakeWrapper.selectExceptionType = SupabaseExceptionType.postgrest;
        fakeWrapper.selectMultipleExceptionType = SupabaseExceptionType.socket;
        fakeWrapper.insertExceptionType = SupabaseExceptionType.timeout;
        fakeWrapper.updateExceptionType = SupabaseExceptionType.auth;
        fakeWrapper.deleteExceptionType = SupabaseExceptionType.type;
        fakeWrapper.rpcExceptionType = SupabaseExceptionType.postgrest;
        fakeWrapper.postgrestErrorCode = PostgresErrorCode.uniqueViolation;
        fakeWrapper.shouldReturnNullUser = true;
        fakeWrapper.shouldReturnNullOnSelect = true;
        fakeWrapper.shouldDelayOperations = true;
        fakeWrapper.completer = Completer();
        fakeWrapper.shouldEmitStreamErrors = true;
        fakeWrapper.shouldReturnUser = true;
        fakeWrapper.shouldThrowOnGetUserProfile = true;
        fakeWrapper.setRpcResponse('test_function', true);

        expect(fakeWrapper.shouldThrowOnDelete, isTrue);
        expect(fakeWrapper.shouldThrowOnRpc, isTrue);
        expect(fakeWrapper.deleteErrorMessage, equals('Delete failed'));
        expect(
          fakeWrapper.deleteExceptionType,
          equals(SupabaseExceptionType.type),
        );
        expect(fakeWrapper.getMethodCalls(), isNotEmpty);
        expect(fakeWrapper.isAuthenticated, isTrue);

        fakeWrapper.reset();

        expect(fakeWrapper.shouldThrowOnSignIn, isFalse);
        expect(fakeWrapper.shouldThrowOnSignUp, isFalse);
        expect(fakeWrapper.shouldThrowOnOtp, isFalse);
        expect(fakeWrapper.shouldThrowOnVerifyOtp, isFalse);
        expect(fakeWrapper.shouldThrowOnResetPassword, isFalse);
        expect(fakeWrapper.shouldThrowOnSignOut, isFalse);
        expect(fakeWrapper.shouldThrowOnSelect, isFalse);
        expect(fakeWrapper.shouldThrowOnInsert, isFalse);
        expect(fakeWrapper.shouldThrowOnUpdate, isFalse);
        expect(fakeWrapper.shouldThrowOnSelectMultiple, isFalse);
        expect(fakeWrapper.shouldThrowOnDelete, isFalse);
        expect(fakeWrapper.shouldThrowOnRpc, isFalse);
        expect(fakeWrapper.signInErrorMessage, isNull);
        expect(fakeWrapper.signUpErrorMessage, isNull);
        expect(fakeWrapper.otpErrorMessage, isNull);
        expect(fakeWrapper.verifyOtpErrorMessage, isNull);
        expect(fakeWrapper.resetPasswordErrorMessage, isNull);
        expect(fakeWrapper.signOutErrorMessage, isNull);
        expect(fakeWrapper.selectErrorMessage, isNull);
        expect(fakeWrapper.insertErrorMessage, isNull);
        expect(fakeWrapper.updateErrorMessage, isNull);
        expect(fakeWrapper.deleteErrorMessage, isNull);
        expect(fakeWrapper.rpcErrorMessage, isNull);
        expect(fakeWrapper.selectExceptionType, isNull);
        expect(fakeWrapper.selectMultipleExceptionType, isNull);
        expect(fakeWrapper.insertExceptionType, isNull);
        expect(fakeWrapper.updateExceptionType, isNull);
        expect(fakeWrapper.deleteExceptionType, isNull);
        expect(fakeWrapper.rpcExceptionType, isNull);
        expect(fakeWrapper.postgrestErrorCode, isNull);
        expect(fakeWrapper.shouldReturnNullUser, isFalse);
        expect(fakeWrapper.shouldReturnNullOnSelect, isFalse);
        expect(fakeWrapper.shouldDelayOperations, isFalse);
        expect(fakeWrapper.completer, isNull);
        expect(fakeWrapper.shouldEmitStreamErrors, isFalse);
        expect(fakeWrapper.shouldReturnUser, isFalse);
        expect(fakeWrapper.shouldThrowOnGetUserProfile, isFalse);
        expect(fakeWrapper.getMethodCalls(), isEmpty);
        expect(fakeWrapper.isAuthenticated, isFalse);

        final userResult = await fakeWrapper.selectSingle(
          table: 'users',
          filterColumn: 'id',
          filterValue: '1',
        );
        expect(userResult, isNull);

        expect(
          () async => await fakeWrapper.rpc<bool>('test_function'),
          throwsA(isA<ServerException>()),
          reason: 'RPC responses should be cleared after reset',
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
