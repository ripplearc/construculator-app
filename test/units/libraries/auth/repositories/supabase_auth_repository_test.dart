import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_repository_impl.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseRepositoryImpl authRepository;

  setUp(() {
    Modular.init(_TestAppModule());
    fakeSupabaseWrapper = Modular.get<SupabaseWrapper>() as FakeSupabaseWrapper;
    authRepository =
        Modular.get<AuthRepository>(key: 'authRepositoryWithFakeDep')
            as SupabaseRepositoryImpl;
  });

  tearDown(() {
    fakeSupabaseWrapper.reset();
    Modular.destroy();
  });

  group('Auth Repository', () {
    group('User Credential Retrieval', () {
      test('getCurrentCredentials returns null when user is null', () {
        fakeSupabaseWrapper.shouldReturnUser = false;
        final credentials = authRepository.getCurrentCredentials();
        expect(credentials, isNull);
      });

      test(
        'getCurrentCredentials should return user if user is already logged in',
        () async {
          fakeSupabaseWrapper.setCurrentUser(
            FakeUser(
              id: 'currentuser123',
              email: 'currentuser@example.com',
              appMetadata: {},
              userMetadata: {},
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
          expect(
            authRepository.getCurrentCredentials()!.email,
            equals('currentuser@example.com'),
          );
          expect(
            authRepository.getCurrentCredentials()!.id,
            equals('currentuser123'),
          );
        },
      );

      test('getCurrentCredentials should map metadata correctly', () async {
        final now = DateTime.now();
        final appMetadata = {
          'role': 'admin',
          'permissions': ['read', 'write'],
        };
        final userMetadata = {'name': 'John Doe', 'theme': 'dark'};

        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: 'user123',
            email: 'user@example.com',
            appMetadata: appMetadata,
            userMetadata: userMetadata,
            createdAt: now.toIso8601String(),
          ),
        );

        final credentials = authRepository.getCurrentCredentials();
        expect(credentials, isNotNull);
        expect(credentials!.id, equals('user123'));
        expect(credentials.email, equals('user@example.com'));
        expect(credentials.metadata['role'], equals('admin'));
        expect(credentials.metadata['permissions'], equals(['read', 'write']));
        expect(credentials.metadata['name'], equals('John Doe'));
        expect(credentials.metadata['theme'], equals('dark'));
        expect(
          credentials.createdAt.toIso8601String(),
          equals(now.toIso8601String()),
        );
      });

      test('getCurrentCredentials should handle empty metadata', () async {
        fakeSupabaseWrapper.setCurrentUser(
          FakeUser(
            id: 'user123',
            email: 'user@example.com',
            appMetadata: {},
            userMetadata: null,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        final credentials = authRepository.getCurrentCredentials();
        expect(credentials, isNotNull);
        expect(credentials!.metadata, isEmpty);
      });
    });
    group('User Profile Management', () {
      group('Retrieve User Profile', () {
        test('should get complete user profile for active user', () async {
          const credentialId = 'cred-123-active-user';
          fakeSupabaseWrapper.addTableData('users', [
            {
              'id': '123',
              'credential_id': credentialId,
              'email': 'project.manager@construction.com',
              'phone': '+1-555-123-4567',
              'first_name': 'Sarah',
              'last_name': 'Johnson',
              'professional_role': 'Project Manager',
              'profile_photo_url':
                  'https://storage.example.com/photos/sarah.jpg',
              'created_at': '2023-01-15T08:30:00Z',
              'updated_at': '2023-12-01T14:22:00Z',
              'user_status': 'active',
              'user_preferences': {
                'theme': 'light',
                'notifications': true,
                'language': 'en',
              },
            },
          ]);

          final result = await authRepository.getUserProfile(credentialId);

          expect(result, isNotNull);
          expect(result!.email, equals('project.manager@construction.com'));
          expect(result.firstName, equals('Sarah'));
          expect(result.lastName, equals('Johnson'));
          expect(result.professionalRole, equals('Project Manager'));
          expect(result.userStatus, equals(UserProfileStatus.active));
          expect(result.userPreferences['theme'], equals('light'));

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
            'selectSingle',
          );
          expect(methodCalls.first['table'], equals('users'));
          expect(methodCalls.first['filterColumn'], equals('credential_id'));
          expect(methodCalls.first['filterValue'], equals(credentialId));
        });

        test(
          'should get complete user profile for active user with string preferences',
          () async {
            const credentialId = 'cred-123-active-user';
            fakeSupabaseWrapper.addTableData('users', [
              {
                'id': '123',
                'credential_id': credentialId,
                'email': 'project.manager@construction.com',
                'phone': '+1-555-123-4567',
                'first_name': 'Sarah',
                'last_name': 'Johnson',
                'professional_role': 'Project Manager',
                'profile_photo_url':
                    'https://storage.example.com/photos/sarah.jpg',
                'created_at': '2023-01-15T08:30:00Z',
                'updated_at': '2023-12-01T14:22:00Z',
                'user_status': 'active',
                'user_preferences': {
                  'theme': 'light',
                  'notifications': true,
                  'language': 'en',
                },
              },
            ]);

            final result = await authRepository.getUserProfile(credentialId);

            expect(result, isNotNull);
            expect(result!.email, equals('project.manager@construction.com'));
            expect(result.firstName, equals('Sarah'));
            expect(result.lastName, equals('Johnson'));
            expect(result.professionalRole, equals('Project Manager'));
            expect(result.userStatus, equals(UserProfileStatus.active));
            expect(result.userPreferences['theme'], equals('light'));

            final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
              'selectSingle',
            );
            expect(methodCalls.first['table'], equals('users'));
            expect(methodCalls.first['filterColumn'], equals('credential_id'));
            expect(methodCalls.first['filterValue'], equals(credentialId));
          },
        );

        test('should get user profile for inactive user', () async {
          const credentialId = 'cred-456-inactive-user';
          final Map<String, dynamic> pref = {};
          fakeSupabaseWrapper.addTableData('users', [
            {
              'id': '456',
              'credential_id': credentialId,
              'email': 'former.employee@construction.com',
              'phone': null,
              'first_name': 'Mike',
              'last_name': 'Chen',
              'professional_role': 'Former Supervisor',
              'profile_photo_url': null,
              'user_status': 'inactive',
              'created_at': '2022-06-01T00:00:00Z',
              'updated_at': '2023-08-15T00:00:00Z',
              'user_preferences': pref,
            },
          ]);

          final result = await authRepository.getUserProfile(credentialId);
          expect(result, isNotNull);
          expect(result!.userStatus, equals(UserProfileStatus.inactive));
          expect(result.userPreferences, isEmpty);
          expect(result.phone, isNull);
          expect(result.profilePhotoUrl, isNull);
        });

        test('should return null for non-existent user profile', () async {
          const nonExistentCredentialId = 'cred-999-not-found';

          final result = await authRepository.getUserProfile(
            nonExistentCredentialId,
          );

          expect(result, isNull);
        });

        group('Exception Handling', () {
          test('should throw on network connection failures', () async {
            fakeSupabaseWrapper.shouldThrowOnSelect = true;
            fakeSupabaseWrapper.selectExceptionType =
                SupabaseExceptionType.socket;
            fakeSupabaseWrapper.selectErrorMessage =
                'Network connection failed';

            expect(
              () => authRepository.getUserProfile('any-id'),
              throwsException,
            );
          });

          test('should throw on request timeouts', () async {
            fakeSupabaseWrapper.shouldThrowOnSelect = true;
            fakeSupabaseWrapper.selectExceptionType =
                SupabaseExceptionType.timeout;
            fakeSupabaseWrapper.selectErrorMessage = 'Request timed out';

            expect(
              () => authRepository.getUserProfile('any-id'),
              throwsException,
            );
          });

          test('should throw on Supabase auth errors', () async {
            fakeSupabaseWrapper.shouldThrowOnSelect = true;
            fakeSupabaseWrapper.authErrorCode =
                SupabaseAuthErrorCode.invalidCredentials;
            fakeSupabaseWrapper.selectErrorMessage = 'Invalid credentials';

            expect(
              () => authRepository.getUserProfile('any-id'),
              throwsException,
            );
          });

          test('should throw on Postgres database errors', () async {
            fakeSupabaseWrapper.shouldThrowOnSelect = true;
            fakeSupabaseWrapper.selectExceptionType =
                SupabaseExceptionType.postgrest;
            fakeSupabaseWrapper.postgrestErrorCode =
                PostgresErrorCode.uniqueViolation;
            fakeSupabaseWrapper.selectErrorMessage = 'Unique violation';

            expect(
              () => authRepository.getUserProfile('any-id'),
              throwsException,
            );
          });

          test('should throw on unknown errors', () async {
            fakeSupabaseWrapper.shouldThrowOnSelect = true;
            fakeSupabaseWrapper.selectExceptionType =
                SupabaseExceptionType.type;
            fakeSupabaseWrapper.selectErrorMessage = 'Unknown error';

            expect(
              () => authRepository.getUserProfile('any-id'),
              throwsA(isA<TypeError>()),
            );
          });
        });
      });

      group('Create User Profile', () {
        test('should create new active user profile', () async {
          final newUser = User(
            id: '',
            credentialId: 'cred-new-active-user',
            email: 'new.engineer@construction.com',
            phone: '+1-555-234-5678',
            firstName: 'Alex',
            lastName: 'Rodriguez',
            professionalRole: 'Site Engineer',
            profilePhotoUrl: 'https://storage.example.com/photos/alex.jpg',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userStatus: UserProfileStatus.active,
            userPreferences: {'theme': 'dark', 'units': 'metric'},
          );

          final result = await authRepository.createUserProfile(newUser);

          expect(result, isNotNull);
          expect(result!.userStatus, equals(UserProfileStatus.active));
          expect(result.email, equals('new.engineer@construction.com'));

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
          expect(methodCalls.first['table'], equals('users'));

          final insertData = methodCalls.first['data'] as Map<String, dynamic>;
          expect(insertData['credential_id'], equals('cred-new-active-user'));
          expect(insertData['email'], equals('new.engineer@construction.com'));
          expect(insertData['user_status'], equals('active'));
          expect(
            insertData['user_preferences'],
            equals({'theme': 'dark', 'units': 'metric'}),
          );
        });

        test('should create new inactive user profile', () async {
          final newUser = User(
            id: '',
            credentialId: 'cred-new-inactive-user',
            email: 'temp.worker@construction.com',
            phone: null,
            firstName: 'Jordan',
            lastName: 'Smith',
            professionalRole: 'Temporary Worker',
            profilePhotoUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            userStatus: UserProfileStatus.inactive,
            userPreferences: {},
          );

          final result = await authRepository.createUserProfile(newUser);
          expect(result, isNotNull);
          expect(result!.userStatus, equals(UserProfileStatus.inactive));
          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('insert');
          final insertData = methodCalls.first['data'] as Map<String, dynamic>;
          expect(insertData['user_status'], equals('inactive'));
        });
      });

      group('Update User Profile', () {
        test('should update existing user profile information', () async {
          const credentialId = 'cred-update-user';
          fakeSupabaseWrapper.addTableData('users', [
            {
              'id': '789',
              'credential_id': credentialId,
              'email': 'old.email@construction.com',
              'user_status': 'inactive',
              'created_at': '2023-01-01T00:00:00Z',
              'updated_at': '2023-01-01T00:00:00Z',
            },
          ]);

          final updatedUser = User(
            id: '789',
            credentialId: credentialId,
            email: 'updated.email@construction.com',
            phone: '+1-555-999-8888',
            firstName: 'Updated',
            lastName: 'Name',
            professionalRole: 'Senior Project Manager',
            profilePhotoUrl: 'https://storage.example.com/photos/updated.jpg',
            createdAt: DateTime.now().subtract(Duration(days: 365)),
            updatedAt: DateTime.now(),
            userStatus: UserProfileStatus.active,
            userPreferences: {'theme': 'auto', 'notifications': false},
          );

          final result = await authRepository.updateUserProfile(updatedUser);

          expect(result, isNotNull);
          expect(result!.userStatus, equals(UserProfileStatus.active));
          expect(result.email, equals('updated.email@construction.com'));

          final methodCalls = fakeSupabaseWrapper.getMethodCallsFor('update');
          expect(methodCalls.first['table'], equals('users'));
          expect(methodCalls.first['filterColumn'], equals('credential_id'));
          expect(methodCalls.first['filterValue'], equals(credentialId));

          final updateData = methodCalls.first['data'] as Map<String, dynamic>;
          expect(updateData['email'], equals('updated.email@construction.com'));
          expect(updateData['user_status'], equals('active'));
          expect(
            updateData['user_preferences'],
            equals({'theme': 'auto', 'notifications': false}),
          );
        });
      });
    });

    group('User Credentials Update', () {
      test(
        'should update both email and password when both are provided',
        () async {
          final fakeUser = FakeUser(
            id: 'user-1',
            email: 'old@example.com',
            appMetadata: {'role': 'user'},
            userMetadata: {},
            createdAt: DateTime.now().toIso8601String(),
          );
          fakeSupabaseWrapper.setCurrentUser(fakeUser);
          fakeSupabaseWrapper.shouldReturnNullUser = false;
          final result = await authRepository.updateUserEmail(
            'new@example.com',
          );
          expect(result, isNotNull);
          expect(result!.email, equals('new@example.com'));
          expect(result.metadata['role'], equals('user'));
        },
      );

      test('should update only email', () async {
        final fakeUser = FakeUser(
          id: 'user-2',
          email: 'old@example.com',
          appMetadata: {'role': 'user'},
          userMetadata: {},
          createdAt: DateTime.now().toIso8601String(),
        );
        fakeSupabaseWrapper.setCurrentUser(fakeUser);
        fakeSupabaseWrapper.shouldReturnNullUser = false;
        final result = await authRepository.updateUserEmail('new@example.com');
        expect(result, isNotNull);
        expect(result!.email, equals('new@example.com'));
        expect(result.metadata['role'], equals('user'));
      });

      test('should update only password', () async {
        final fakeUser = FakeUser(
          id: 'user-3',
          email: 'old@example.com',
          appMetadata: {'role': 'user'},
          userMetadata: {},
          createdAt: DateTime.now().toIso8601String(),
        );
        fakeSupabaseWrapper.setCurrentUser(fakeUser);
        fakeSupabaseWrapper.shouldReturnNullUser = false;
        final result = await authRepository.updateUserPassword('newpass123');
        expect(result, isNotNull);
        expect(result!.email, equals('old@example.com'));
        expect(result.metadata['role'], equals('user'));
      });

      test(
        'should return null if wrapper returns null user for email update',
        () async {
          fakeSupabaseWrapper.shouldReturnNullUser = true;
          final result = await authRepository.updateUserEmail(
            'any@example.com',
          );
          expect(result, isNull);
        },
      );

      test(
        'should return null if wrapper returns null user for password update',
        () async {
          fakeSupabaseWrapper.shouldReturnNullUser = true;
          final result = await authRepository.updateUserPassword('pass');
          expect(result, isNull);
        },
      );

      test('should throw if wrapper throws for email update', () async {
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.updateErrorMessage = 'Update failed';
        expect(
          () => authRepository.updateUserEmail('fail@example.com'),
          throwsException,
        );
      });

      test('should throw if wrapper throws for password update', () async {
        fakeSupabaseWrapper.shouldThrowOnUpdate = true;
        fakeSupabaseWrapper.updateExceptionType = SupabaseExceptionType.auth;
        fakeSupabaseWrapper.updateErrorMessage = 'Update failed';
        expect(
          () => authRepository.updateUserPassword('fail'),
          throwsException,
        );
      });

      test(
        'should call updateUser on the wrapper with correct attributes for email',
        () async {
          final fakeUser = FakeUser(
            id: 'user-4',
            email: 'old@example.com',
            appMetadata: {'role': 'user'},
            userMetadata: {},
            createdAt: DateTime.now().toIso8601String(),
          );
          fakeSupabaseWrapper.setCurrentUser(fakeUser);
          fakeSupabaseWrapper.shouldReturnNullUser = false;
          await authRepository.updateUserEmail('new@example.com');
          final calls = fakeSupabaseWrapper.getMethodCallsFor('updateUser');
          expect(calls, isNotEmpty);
          final attrs = calls.last['userAttributes'];
          expect(attrs.email, equals('new@example.com'));
          expect(attrs.password, isNull);
        },
      );

      test(
        'should call updateUser on the wrapper with correct attributes for password',
        () async {
          final fakeUser = FakeUser(
            id: 'user-5',
            email: 'old@example.com',
            appMetadata: {'role': 'user'},
            userMetadata: {},
            createdAt: DateTime.now().toIso8601String(),
          );
          fakeSupabaseWrapper.setCurrentUser(fakeUser);
          fakeSupabaseWrapper.shouldReturnNullUser = false;
          await authRepository.updateUserPassword('newpass123');
          final calls = fakeSupabaseWrapper.getMethodCallsFor('updateUser');
          expect(calls, isNotEmpty);
          final attrs = calls.last['userAttributes'];
          expect(attrs.email, isNull);
          expect(attrs.password, equals('newpass123'));
        },
      );
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [AuthTestModule()];
}
