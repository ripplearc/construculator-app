import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/auth/testing/auth_test_module.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/errors/exceptions.dart';

void main() {
  late FakeAuthRepository fakeRepository;
  late Clock clock;

  User createFakeUser({String? credentialId, String? email, String? id}) {
    return User(
      id: id ?? 'fake-user-id',
      credentialId: credentialId,
      email: email ?? 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      professionalRole: 'fake-role-id',
      createdAt: clock.now(),
      updatedAt: clock.now(),
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
    fakeRepository.setAuthResponse(succeed: true);
    clock = Modular.get<Clock>();
  });

  tearDown(() {
    Modular.destroy();
  });

  group('FakeAuthRepository', () {
    group('Credential Management', () {
      test('returns null when no credentials have been set', () {
        final credentials = fakeRepository.getCurrentCredentials();
        expect(credentials, isNull);
      });

      test('returns credentials after they are set', () {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {'role': 'user'},
          createdAt: clock.now(),
        );

        fakeRepository.setCurrentCredentials(testCredential);

        final credentials = fakeRepository.getCurrentCredentials();
        expect(credentials, isNotNull);
        expect(credentials!.id, equals('test-id'));
        expect(credentials.email, equals('test@example.com'));
        expect(credentials.metadata['role'], equals('user'));
      });

      test('throws exception when configured to fail', () {
        fakeRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Auth failed',
        );

        expect(
          () => fakeRepository.getCurrentCredentials(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('Email Updates', () {
      test('updates email and returns updated credentials', () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'old@example.com',
          metadata: {'role': 'user'},
          createdAt: clock.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);

        final result = await fakeRepository.updateUserEmail('new@example.com');

        expect(result, isNotNull);
        expect(result!.email, equals('new@example.com'));
        expect(result.metadata['role'], equals('user'));
      });

      test('returns null when no current user exists', () async {
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.updateUserEmail('any@example.com');

        expect(result, isNull);
      });

      test('throws exception when configured to fail', () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'old@example.com',
          metadata: {'role': 'user'},
          createdAt: clock.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);
        fakeRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Update failed',
        );

        expect(
          () async => await fakeRepository.updateUserEmail('fail@example.com'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('Password Updates', () {
      test('updates password and preserves email', () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {'role': 'user'},
          createdAt: clock.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);

        final result = await fakeRepository.updateUserPassword('newpass123');

        expect(result, isNotNull);
        expect(result!.email, equals('test@example.com'));
        expect(result.metadata['password'], equals('newpass123'));
        expect(result.metadata['role'], equals('user'));
      });

      test('returns null when no current user exists', () async {
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.updateUserPassword(
          'newpassword123',
        );

        expect(result, isNull);
      });

      test('throws exception when configured to fail', () async {
        final testCredential = UserCredential(
          id: 'test-id',
          email: 'test@example.com',
          metadata: {'role': 'user'},
          createdAt: clock.now(),
        );
        fakeRepository.setCurrentCredentials(testCredential);
        fakeRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Password update failed',
        );

        expect(
          () async => await fakeRepository.updateUserPassword('newpassword123'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('User Profile Creation', () {
      test('creates profile and allows retrieval', () async {
        final fakeUser = createFakeUser(credentialId: 'test-cred-id');
        fakeRepository.setAuthResponse(succeed: true);

        final created = await fakeRepository.createUserProfile(fakeUser);
        expect(created, isNotNull);
        expect(created!.email, fakeUser.email);

        final retrieved = await fakeRepository.getUserProfile(
          fakeUser.credentialId!,
        );
        expect(retrieved, isNotNull);
        expect(retrieved!.email, fakeUser.email);
        expect(retrieved.credentialId, fakeUser.credentialId);
      });

      test('throws exception when credentialId is null', () async {
        final fakeUser = createFakeUser(credentialId: null);
        fakeRepository.setAuthResponse(succeed: true);

        expect(
          () async => await fakeRepository.createUserProfile(fakeUser),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws exception when configured to fail', () async {
        final fakeUser = createFakeUser(credentialId: 'test-cred-id');
        fakeRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Profile creation failed',
        );

        expect(
          () async => await fakeRepository.createUserProfile(fakeUser),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('User Profile Retrieval', () {
      test('returns null when profile does not exist', () async {
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.getUserProfile('non-existent-id');

        expect(result, isNull);
      });

      test('returns profile after it has been created', () async {
        final fakeUser = createFakeUser(credentialId: 'test-cred-id');
        await fakeRepository.createUserProfile(fakeUser);
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.getUserProfile(
          fakeUser.credentialId!,
        );

        expect(result, isNotNull);
        expect(result!.email, fakeUser.email);
        expect(result.credentialId, fakeUser.credentialId);
      });

      test('returns null when configured to return null', () async {
        fakeRepository.returnNullUserProfile = true;

        final result = await fakeRepository.getUserProfile('any-id');

        expect(result, isNull);
      });

      test('throws exception when configured to throw', () async {
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
    });

    group('User Profile Updates', () {
      test('updates existing profile and persists changes', () async {
        final originalUser = createFakeUser(
          email: 'original@example.com',
          credentialId: 'cred-original',
        );
        fakeRepository.setAuthResponse(succeed: true);

        await fakeRepository.createUserProfile(originalUser);

        final updatedUser = originalUser.copyWith(firstName: 'UpdatedName');
        final result = await fakeRepository.updateUserProfile(updatedUser);

        expect(result, isNotNull);
        expect(result!.firstName, 'UpdatedName');

        final retrieved = await fakeRepository.getUserProfile(
          originalUser.credentialId!,
        );
        expect(retrieved, isNotNull);
        expect(retrieved!.firstName, 'UpdatedName');
      });

      test('returns null when profile does not exist', () async {
        final nonExistentUser = createFakeUser(
          credentialId: 'non-existent-for-update',
        );
        fakeRepository.setAuthResponse(succeed: true);

        final result = await fakeRepository.updateUserProfile(nonExistentUser);

        expect(result, isNull);
      });

      test('throws exception when credentialId is null', () async {
        final fakeUser = createFakeUser(credentialId: null);
        fakeRepository.setAuthResponse(succeed: true);

        expect(
          () async => await fakeRepository.updateUserProfile(fakeUser),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws exception when configured to fail', () async {
        final fakeUser = createFakeUser(credentialId: 'test-cred-id');

        await fakeRepository.createUserProfile(fakeUser);

        fakeRepository.setAuthResponse(
          succeed: false,
          errorMessage: 'Profile update failed',
        );

        expect(
          () async => await fakeRepository.updateUserProfile(fakeUser),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('Test Setup Utilities', () {
      test('allows setting up multiple test profiles', () async {
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
          testUser1.credentialId!,
        );
        expect(result1, isNotNull);
        expect(result1!.email, 'user1@test.com');

        final result2 = await fakeRepository.getUserProfile(
          testUser2.credentialId!,
        );
        expect(result2, isNotNull);
        expect(result2!.email, 'user2@test.com');
      });

      test('throws exception when setting profile with null credentialId', () {
        final testUser = createFakeUser(credentialId: null);

        expect(
          () => fakeRepository.setUserProfile(testUser),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}

class _TestAppModule extends Module {
  @override
  List<Module> get imports => [AuthTestModule()];
}
