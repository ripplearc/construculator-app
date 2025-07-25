import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/errors/exceptions.dart';

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
    fakeRepository =
        Modular.get<AuthRepository>(key: 'fakeAuthRepository')
            as FakeAuthRepository;
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
    test(
      'updateUserCredentials should update only email if password is null',
      () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'old@example.com',
          metadata: {'role': 'user'},
          createdAt: DateTime.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);
        final result = await fakeRepository.updateUserEmail('new@example.com');
        expect(result, isNotNull);
        expect(result!.email, equals('new@example.com'));
        expect(result.metadata.containsKey('password'), isFalse);
        expect(result.metadata['role'], equals('user'));
      },
    );

    test(
      'updateUserCredentials should update only password if email is null',
      () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'old@example.com',
          metadata: {'role': 'user'},
          createdAt: DateTime.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);
        final result = await fakeRepository.updateUserPassword('newpass123');
        expect(result, isNotNull);
        expect(result!.email, equals('old@example.com'));
        expect(result.metadata['password'], equals('newpass123'));
        expect(result.metadata['role'], equals('user'));
      },
    );

    test(
      'updateUserCredentials should return null if no current user',
      () async {
        fakeRepository.setAuthResponse(succeed: true);
        final result = await fakeRepository.updateUserEmail('any@example.com');
        expect(result, isNull);
      },
    );

    test('updateUserCredentials should throw if configured to fail', () async {
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'old@example.com',
        metadata: {'role': 'user'},
        createdAt: DateTime.now(),
      );
      fakeRepository.setCurrentCredentials(testCredential);
      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Update failed',
      );
      expect(
        () => fakeRepository.updateUserEmail('fail@example.com'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('Database Operations - User Profiles', () {
    test('getUserProfile should return profile when it exists', () async {
      final fakeUser = createFakeUser();
      await fakeRepository.createUserProfile(fakeUser);
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.getUserProfile(fakeUser.credentialId);

      expect(result, isNotNull);
      expect(result!.email, fakeUser.email);
      expect(result.credentialId, fakeUser.credentialId);
      expect(
        fakeRepository.getUserProfileCalls,
        contains(fakeUser.credentialId),
      );
    });

    test(
      'getUserProfile should return null when profile does not exist',
      () async {
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.getUserProfile('non-existent-id');

        expect(result, isNull);
        expect(fakeRepository.getUserProfileCalls, contains('non-existent-id'));
      },
    );

    test('getUserProfile should throw when configured to fail', () async {
      fakeRepository.shouldThrowOnGetUserProfile = true;
      fakeRepository.exceptionMessage = 'Failed to get profile';

      expect(
        () => fakeRepository.getUserProfile('any-id'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to get profile'),
          ),
        ),
      );
    });

    test(
      'getUserProfile should return null when configured to return null',
      () async {
        fakeRepository.returnNullUserProfile = true;
        final result = await fakeRepository.getUserProfile('any-id');
        expect(result, isNull);
      },
    );

    test(
      'createUserProfile should succeed when configured to succeed',
      () async {
        final fakeUser = createFakeUser();
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.createUserProfile(fakeUser);

        expect(result, isNotNull);
        expect(result!.email, fakeUser.email);
        expect(result.credentialId, fakeUser.credentialId);
        expect(fakeRepository.createProfileCalls, contains(fakeUser));

        final fetchResult = await fakeRepository.getUserProfile(
          fakeUser.credentialId,
        );
        expect(fetchResult, isNotNull);
        expect(fetchResult!.email, fakeUser.email);
      },
    );

    test('createUserProfile should throw when configured to fail', () async {
      final fakeUser = createFakeUser();
      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Profile creation failed',
      );

      expect(
        () => fakeRepository.createUserProfile(fakeUser),
        throwsA(isA<ServerException>()),
      );
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
        final createdUser = await fakeRepository.createUserProfile(
          originalUser,
        );
        expect(
          createdUser,
          isNotNull,
          reason: 'Pre-condition: Create profile failed',
        );

        final updatedUser = originalUser.copyWith(firstName: 'UpdatedName');

        final result = await fakeRepository.updateUserProfile(updatedUser);

        expect(result, isNotNull);
        expect(result!.firstName, 'UpdatedName');
        expect(result.credentialId, originalUser.credentialId);
        expect(fakeRepository.updateProfileCalls, contains(updatedUser));

        // Verify the update is reflected
        final fetchResult = await fakeRepository.getUserProfile(
          originalUser.credentialId,
        );
        expect(fetchResult, isNotNull);
        expect(fetchResult!.firstName, 'UpdatedName');
      },
    );

    test('updateUserProfile should throw when configured to fail', () async {
      final fakeUser = createFakeUser();

      await fakeRepository.createUserProfile(fakeUser);

      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Profile update failed',
      );

      expect(
        () => fakeRepository.updateUserProfile(fakeUser),
        throwsA(isA<ServerException>()),
      );
      expect(fakeRepository.updateProfileCalls, contains(fakeUser));
    });

    test(
      'updateUserProfile should return null if profile does not exist',
      () async {
        final nonExistentUser = createFakeUser(
          credentialId: 'non-existent-for-update',
        );
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.updateUserProfile(nonExistentUser);

        expect(result, isNull);
        expect(fakeRepository.updateProfileCalls, contains(nonExistentUser));
      },
    );
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
      expect(result1, isNotNull);
      expect(result1!.email, 'user1@test.com');
      expect(result1.id, testUser1.id);

      final result2 = await fakeRepository.getUserProfile(
        testUser2.credentialId,
      );
      expect(result2, isNotNull);
      expect(result2!.email, 'user2@test.com');
      expect(result2.id, testUser2.id);
    });
  });

  group('Email Update Operations', () {
    test('updateUserEmail should succeed when configured to succeed', () async {
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'old@example.com',
        metadata: {'role': 'user'},
        createdAt: DateTime.now(),
      );
      fakeRepository.setCurrentCredentials(testCredential);
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.updateUserEmail('new@example.com');

      expect(result, isNotNull);
      expect(result!.email, equals('new@example.com'));
      expect(result.id, equals('test-id'));
      expect(result.metadata['role'], equals('user'));
      expect(fakeRepository.updateEmailCalls, contains('new@example.com'));
    });

    test('updateUserEmail should throw when configured to fail', () async {
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'old@example.com',
        metadata: {'role': 'user'},
        createdAt: DateTime.now(),
      );
      fakeRepository.setCurrentCredentials(testCredential);
      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Email update failed',
      );

      expect(
        () => fakeRepository.updateUserEmail('new@example.com'),
        throwsA(isA<ServerException>()),
      );
      expect(fakeRepository.updateEmailCalls, contains('new@example.com'));
    });

    test('updateUserEmail should return null if no current user', () async {
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.updateUserEmail('new@example.com');

      expect(result, isNull);
      expect(fakeRepository.updateEmailCalls, contains('new@example.com'));
    });
  });

  group('Password Update Operations', () {
    test(
      'updateUserPassword should succeed when configured to succeed',
      () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {'role': 'user'},
          createdAt: DateTime.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.updateUserPassword(
          'newpassword123',
        );

        expect(result, isNotNull);
        expect(result!.email, equals('test@example.com'));
        expect(result.id, equals('test-id'));
        expect(result.metadata['password'], equals('newpassword123'));
        expect(result.metadata['role'], equals('user'));
        expect(fakeRepository.updatePasswordCalls, contains('newpassword123'));
      },
    );

    test('updateUserPassword should throw when configured to fail', () async {
      final testCredential = UserCredential(
        id: 'test-id',
        email: 'test@example.com',
        metadata: {'role': 'user'},
        createdAt: DateTime.now(),
      );
      fakeRepository.setCurrentCredentials(testCredential);
      fakeRepository.setAuthResponse(
        succeed: false,
        errorMessage: 'Password update failed',
      );

      expect(
        () => fakeRepository.updateUserPassword('newpassword123'),
        throwsA(isA<ServerException>()),
      );
      expect(fakeRepository.updatePasswordCalls, contains('newpassword123'));
    });

    test('updateUserPassword should return null if no current user', () async {
      fakeRepository.setAuthResponse(succeed: true);

      final result = await fakeRepository.updateUserPassword('newpassword123');

      expect(result, isNull);
      expect(fakeRepository.updatePasswordCalls, contains('newpassword123'));
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [AuthTestModule()];
}
