import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/repositories/supabase_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseWrapper fakeSupabaseWrapper;
  late SupabaseAuthRepository authRepository;

  setUp(() {
    fakeSupabaseWrapper = FakeSupabaseWrapper();
    authRepository = SupabaseAuthRepository(supabaseWrapper: fakeSupabaseWrapper);
  });

  tearDown(() {
    // Ensure resources are cleaned up after each test.
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
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

        expect(result.isSuccess, isTrue);
        expect(
          result.data?.email,
          equals('project.manager@construction.com'),
        );
        expect(result.data?.firstName, equals('Sarah'));
        expect(result.data?.lastName, equals('Johnson'));
        expect(result.data?.professionalRole, equals('Project Manager'));
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.userPreferences['theme'], equals('light'));

        final methodCalls = fakeSupabaseWrapper.getMethodCallsFor(
          'selectSingle',
        );
        expect(methodCalls.first['table'], equals('users'));
        expect(methodCalls.first['filterColumn'], equals('credential_id'));
        expect(methodCalls.first['filterValue'], equals(credentialId));
      });

      test('should get user profile for inactive user', () async {
        const credentialId = 'cred-456-inactive-user';
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
            'user_preferences': null,
          },
        ]);

        final result = await authRepository.getUserProfile(credentialId);

        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.inactive));
        expect(result.data?.userPreferences, isEmpty);
        expect(result.data?.phone, isNull);
        expect(result.data?.profilePhotoUrl, isNull);
      });

      test('should handle request for non-existent user profile', () async {
        // No user data added
        const nonExistentCredentialId = 'cred-999-not-found';

        final result = await authRepository.getUserProfile(
          nonExistentCredentialId,
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorType, equals(AuthErrorType.userNotFound));
        expect(result.errorMessage, contains('User profile not found'));
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

        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.email, equals('new.engineer@construction.com'));

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

        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.inactive));

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

        expect(result.isSuccess, isTrue);
        expect(result.data?.userStatus, equals(UserProfileStatus.active));
        expect(result.data?.email, equals('updated.email@construction.com'));

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
} 