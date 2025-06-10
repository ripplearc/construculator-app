import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';

// Helper function to create fake users for testing
User _createFakeUser({String? credentialId, String? email}) {
  return User(
    id: 'fake-user-id', // Default ID, might be overwritten by fake repo
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

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  group('Database Operations - User Profiles', () {
    test('getUserProfile should return profile when it exists', () async {
      // Arrange
      final fakeUser = _createFakeUser();
      // The fakeUserProfile method in FakeAuthRepository might assign its own ID to the stored profile.
      // We need to ensure the profile is actually stored and then retrieved.
      // Create user first so it's in the "database"
      await fakeRepository.createUserProfile(fakeUser);
      // Then configure the response for getUserProfile
      fakeRepository.fakeAuthResponse(succeed: true); 
      // fakeUserProfile is more for direct injection, let's rely on createUserProfile for this test.
      // And then try to get it by the credentialId used or email.
      // The fake repo stores profiles by credentialId after createUserProfile.

      // Act
      final result = await fakeRepository.getUserProfile(
        fakeUser.credentialId,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      // The ID assigned by createUserProfile might be different ('profile-${email_prefix}')
      // Let's check email for consistency as credentialId is the lookup key.
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
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true); // The call itself succeeds, but finds nothing

        // Act
        final result = await fakeRepository.getUserProfile('non-existent-id');

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
        expect(
          fakeRepository.getUserProfileCalls,
          contains('non-existent-id'),
        );
      },
    );

    test(
      'getUserProfile should return user not found when returnNullUserProfile is true',
      () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true); // The call itself is not failing
        fakeRepository.returnNullUserProfile = true;

        // Act
        final result = await fakeRepository.getUserProfile('any-id');

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
      },
    );

    test(
      'createUserProfile should succeed when configured to succeed',
      () async {
        // Arrange
        final fakeUser = _createFakeUser();
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.createUserProfile(fakeUser);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        // The implementation creates a new ID: 'profile-${user.email.split('@')[0]}'
        // For test@example.com, this would be profile-test
        // But the fakeUser passed in already has an id.
        // The fake repo actually uses the credentialId to store and user.id for the returned User object.
        // Let's check a few key fields.
        expect(result.data!.email, fakeUser.email);
        expect(result.data!.credentialId, fakeUser.credentialId);
        expect(fakeRepository.createProfileCalls, contains(fakeUser));

        // Verify it can be fetched
        final fetchResult = await fakeRepository.getUserProfile(fakeUser.credentialId);
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.email, fakeUser.email);
      },
    );

    test('createUserProfile should fail when configured to fail', () async {
      // Arrange
      final fakeUser = _createFakeUser();
      fakeRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Profile creation failed',
      );

      // Act
      final result = await fakeRepository.createUserProfile(fakeUser);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Profile creation failed');
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.createProfileCalls, contains(fakeUser));
    });

    test(
      'updateUserProfile should succeed when configured to succeed',
      () async {
        // Arrange
        final originalUser = _createFakeUser(email: 'original@example.com', credentialId: 'cred-original');
        fakeRepository.fakeAuthResponse(succeed: true);

        // First create the profile so it exists for update
        final createResult = await fakeRepository.createUserProfile(originalUser);
        expect(createResult.isSuccess, true, reason: "Pre-condition: Create profile failed");
        
        final updatedUser = originalUser.copyWith(firstName: 'UpdatedName');

        // Act
        final result = await fakeRepository.updateUserProfile(updatedUser);

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.firstName, 'UpdatedName');
        expect(result.data!.email, originalUser.email); // Email should not change on update typically
        expect(result.data!.credentialId, originalUser.credentialId);
        expect(fakeRepository.updateProfileCalls, contains(updatedUser));

        // Verify the update is reflected
        final fetchResult = await fakeRepository.getUserProfile(originalUser.credentialId);
        expect(fetchResult.isSuccess, true);
        expect(fetchResult.data!.firstName, 'UpdatedName');
      },
    );

    test('updateUserProfile should fail when configured to fail', () async {
      // Arrange
      final fakeUser = _createFakeUser();
      // Ensure profile exists
      await fakeRepository.createUserProfile(fakeUser); 
      
      fakeRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Profile update failed',
      );

      // Act
      final result = await fakeRepository.updateUserProfile(fakeUser);

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Profile update failed');
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.updateProfileCalls, contains(fakeUser));
    });

    test('updateUserProfile should fail if profile does not exist', () async {
        // Arrange
        final nonExistentUser = _createFakeUser(credentialId: 'non-existent-for-update');
        fakeRepository.fakeAuthResponse(succeed: true); // Configure for successful call if user existed

        // Act
        final result = await fakeRepository.updateUserProfile(nonExistentUser);

        // Assert (FakeAuthRepository specific behavior: it returns error if profile not found for update)
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'User profile not found');
        expect(result.errorType, AuthErrorType.userNotFound);
        expect(fakeRepository.updateProfileCalls, contains(nonExistentUser));
    });
  });
} 