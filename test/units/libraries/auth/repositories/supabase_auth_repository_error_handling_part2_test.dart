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
    authRepository.dispose();
    fakeSupabaseWrapper.dispose();
    fakeSupabaseWrapper.reset();
  });

  group('Error Handling and Edge Cases Part 2', () {
    test('should handle email registration check errors', () async {
      fakeSupabaseWrapper.shouldThrowOnSelect = true;
      fakeSupabaseWrapper.selectErrorMessage = 'Database error';

      final result = await authRepository.isEmailRegistered(
        'test@example.com',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile retrieval errors', () async {
      fakeSupabaseWrapper.shouldThrowOnSelect = true;
      fakeSupabaseWrapper.selectErrorMessage = 'Profile fetch failed';

      final result = await authRepository.getUserProfile(
        'test-credential-id',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile creation errors', () async {
      fakeSupabaseWrapper.shouldThrowOnInsert = true;
      fakeSupabaseWrapper.insertErrorMessage = 'Profile creation failed';

      final user = User(
        id: 'test-id',
        credentialId: 'test-credential-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      final result = await authRepository.createUserProfile(user);

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test('should handle user profile update errors', () async {
      fakeSupabaseWrapper.shouldThrowOnUpdate = true;
      fakeSupabaseWrapper.updateErrorMessage = 'Profile update failed';

      final user = User(
        id: 'test-id',
        credentialId: 'test-credential-id',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        professionalRole: 'Developer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userStatus: UserProfileStatus.active,
        userPreferences: {},
      );

      final result = await authRepository.updateUserProfile(user);

      expect(result.isSuccess, isFalse);
      expect(result.errorType, equals(AuthErrorType.serverError));
    });

    test(
      'should handle user preferences as string in profile parsing',
      () async {
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences':
                '{"theme": "dark", "notifications": true}', // String JSON
          },
        ]);

        final result = await authRepository.getUserProfile(
          'test-credential-id',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, isA<Map<String, dynamic>>());
        expect(result.data?.userPreferences['theme'], equals('dark'));
        expect(result.data?.userPreferences['notifications'], equals(true));
      },
    );

    test('should handle null user preferences in profile parsing', () async {
      fakeSupabaseWrapper.addTableData('users', [
        {
          'id': 'test-id',
          'credential_id': 'test-credential-id',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'Test',
          'last_name': 'User',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'user_status': 'active',
          'user_preferences': null, // Null preferences
        },
      ]);

      final result = await authRepository.getUserProfile(
        'test-credential-id',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.userPreferences, equals({}));
    });

    test('should handle inactive user status in profile parsing', () async {
      fakeSupabaseWrapper.addTableData('users', [
        {
          'id': 'test-id',
          'credential_id': 'test-credential-id',
          'email': 'test@example.com',
          'phone': null,
          'first_name': 'Test',
          'last_name': 'User',
          'professional_role': 'Developer',
          'profile_photo_url': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'user_status': 'inactive', // Inactive status
          'user_preferences': {},
        },
      ]);

      final result = await authRepository.getUserProfile(
        'test-credential-id',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data?.userStatus, equals(UserProfileStatus.inactive));
    });

    test(
      'should handle user preferences as map in create profile response',
      () async {
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'dark'},
        );

        final result = await authRepository.createUserProfile(user);

        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({'theme': 'dark'}));
      },
    );

    test(
      'should handle empty user preferences in create profile response',
      () async {
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        final result = await authRepository.createUserProfile(user);

        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({}));
      },
    );

    test(
      'should handle user preferences as map in update profile response',
      () async {
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {'theme': 'light'},
        );

        // First create the user in the table
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences': {'theme': 'dark'},
          },
        ]);

        final result = await authRepository.updateUserProfile(user);

        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({'theme': 'light'}));
      },
    );

    test(
      'should handle empty user preferences in update profile response',
      () async {
        final user = User(
          id: 'test-id',
          credentialId: 'test-credential-id',
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
          professionalRole: 'Developer',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userStatus: UserProfileStatus.active,
          userPreferences: {},
        );

        // First create the user in the table
        fakeSupabaseWrapper.addTableData('users', [
          {
            'id': 'test-id',
            'credential_id': 'test-credential-id',
            'email': 'test@example.com',
            'phone': null,
            'first_name': 'Test',
            'last_name': 'User',
            'professional_role': 'Developer',
            'profile_photo_url': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_status': 'active',
            'user_preferences': 'not_a_map',
          },
        ]);

        final result = await authRepository.updateUserProfile(user);

        expect(result.isSuccess, isTrue);
        expect(result.data?.userPreferences, equals({}));
      },
    );
  });
} 