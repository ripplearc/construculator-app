import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  User createFakeUser({String? credentialId, String? email, String? id}) {
    return User(
      id: id ?? 'fake-user-id',
      credentialId: credentialId ?? 'fake-credential-id',
      email: email ?? 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'fake-role-id',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: UserProfileStatus.active,
      userPreferences: {},
      profilePhotoUrl: null,
      phone: null,
    );
  }

  setUp(() {
    Modular.init(_TestAppModule());
    fakeRepository = Modular.get<AuthRepository>(key: 'fakeAuthRepository') as FakeAuthRepository;
    // Default to successful responses unless a test configures otherwise
    fakeRepository.setAuthResponse(succeed: true);
  });

  tearDown(() {
    Modular.destroy();
  });

  group('Credential Management', () {
    test('getCurrentCredentials should track call count', () {
      expect(fakeRepository.getCurrentUserCallCount, equals(0));

      fakeRepository.getCurrentCredentials();
      expect(fakeRepository.getCurrentUserCallCount, equals(1));

      fakeRepository.getCurrentCredentials();
      expect(fakeRepository.getCurrentUserCallCount, equals(2));
    });

    test('getCurrentCredentials should return null by default', () {
      final credentials = fakeRepository.getCurrentCredentials();
      expect(credentials, isNull);
    });

    test('getCurrentCredentials should return set credentials', () {
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'test@example.com',
        metadata: {'role': 'user'},
        createdAt: DateTime.now(),
      );

      fakeRepository.setCurrentCredentials(testCredential);

      final credentials = fakeRepository.getCurrentCredentials();
      expect(credentials, isNotNull);
      expect(credentials!.id, equals('test-id'));
      expect(credentials.email, equals('test@example.com'));
      expect(credentials.metadata['role'], equals('user'));
    });
  });

  group('Database Operations - User Profiles', () {
    test('getUserProfile should return profile when it exists', () async {
      final fakeUser = createFakeUser();
      await fakeRepository.createUserProfile(fakeUser);
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.getUserProfile(fakeUser.credentialId);

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.email, fakeUser.email);
      expect(result.data!.credentialId, fakeUser.credentialId);
      expect(
        fakeRepository.getUserProfileCalls,
        contains(fakeUser.credentialId),
      );
    });

    test(
      'getUserProfile should return user not found when profile does not exist',
      () async {
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.getUserProfile('non-existent-id');

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
        expect(fakeRepository.getUserProfileCalls, contains('non-existent-id'));
      },
    );

    test(
      'getUserProfile should return user not found when returnNullUserProfile is true',
      () async {
        fakeRepository.setAuthResponse(succeed: true);
        fakeRepository.returnNullUserProfile = true;

        final result = await fakeRepository.getUserProfile('any-id');

        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
      },
    );

    test(
      'createUserProfile should succeed when configured to succeed',
      () async {
        final fakeUser = createFakeUser();
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.createUserProfile(fakeUser);

        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.email, fakeUser.email);
        expect(result.data!.credentialId, fakeUser.credentialId);
        expect(fakeRepository.createProfileCalls, contains(fakeUser));

        final fetchResult = await fakeRepository.getUserProfile(
          fakeUser.credentialId,
        );
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.email, fakeUser.email);
      },
    );

    test('createUserProfile should fail when configured to fail', () async {
      final fakeUser = createFakeUser();
      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Profile creation failed',
      );

      final result = await fakeRepository.createUserProfile(fakeUser);

      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Profile creation failed');
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.createProfileCalls, contains(fakeUser));
    });

    test(
      'updateUserProfile should succeed when configured to succeed',
      () async {
        final originalUser = createFakeUser(
          email: 'original@example.com',
          credentialId: 'cred-original',
        );
        fakeRepository.setAuthResponse(succeed: true);

        // First create the profile so it exists for update
        final createResult = await fakeRepository.createUserProfile(
          originalUser,
        );
        expect(
          createResult.isSuccess,
          true,
          reason: "Pre-condition: Create profile failed",
        );

        final updatedUser = originalUser.copyWith(firstName: 'UpdatedName');

        final result = await fakeRepository.updateUserProfile(updatedUser);

        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.firstName, 'UpdatedName');
        expect(result.data!.credentialId, originalUser.credentialId);
        expect(fakeRepository.updateProfileCalls, contains(updatedUser));

        // Verify the update is reflected
        final fetchResult = await fakeRepository.getUserProfile(
          originalUser.credentialId,
        );
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.firstName, 'UpdatedName');
      },
    );

    test('updateUserProfile should fail when configured to fail', () async {
      final fakeUser = createFakeUser();

      await fakeRepository.createUserProfile(fakeUser);

      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Profile update failed',
      );

      final result = await fakeRepository.updateUserProfile(fakeUser);

      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Profile update failed');
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.updateProfileCalls, contains(fakeUser));
    });

    test('updateUserProfile should fail if profile does not exist', () async {
      final nonExistentUser = createFakeUser(
        credentialId: 'non-existent-for-update',
      );
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.updateUserProfile(nonExistentUser);

      expect(result.isSuccess, false);
      expect(result.errorMessage, 'User profile not found');
      expect(result.errorType, AuthErrorType.userNotFound);
      expect(fakeRepository.updateProfileCalls, contains(nonExistentUser));
    });
  });

  group('Test Utility Features', () {
    test('setUserProfile should allow setting up test user profiles', () async {
      final testUser1 = createFakeUser(
        credentialId: 'cred-1',
        email: 'user1@test.com',
        id: 'user1-id',
      );
      final testUser2 = createFakeUser(
        credentialId: 'cred-2',
        email: 'user2@test.com',
        id: 'user2-id',
      );

      fakeRepository.setUserProfile(testUser1);
      fakeRepository.setUserProfile(testUser2);
      fakeRepository.setAuthResponse(succeed: true);

      final result1 = await fakeRepository.getUserProfile(
        testUser1.credentialId,
      );
      expect(result1.isSuccess, true);
      expect(result1.data!.email, 'user1@test.com');
      expect(result1.data!.id, testUser1.id);

      final result2 = await fakeRepository.getUserProfile(
        testUser2.credentialId,
      );
      expect(result2.isSuccess, true);
      expect(result2.data!.email, 'user2@test.com');
      expect(result2.data!.id, testUser2.id);
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [
    AuthTestModule(),
  ];
}