import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/testing/fake_auth_repository.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  late FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeAuthRepository();
  });

  tearDown(() {
    fakeRepository.dispose();
  });

  group('Core Authentication Functionality', () {
    test(
      'loginWithEmail should succeed when configured to succeed',
      () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.loginWithEmail(
          'test@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.email, 'test@example.com');
        expect(fakeRepository.isAuthenticated(), true);
        expect(
          fakeRepository.loginCalls,
          contains('test@example.com:password'),
        );
      },
    );

    test('loginWithEmail should fail when configured to fail', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Invalid credentials',
      );

      // Act
      final result = await fakeRepository.loginWithEmail(
        'test@example.com',
        'wrong-password',
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Invalid credentials');
      expect(result.errorType, AuthErrorType.invalidCredentials);
      expect(fakeRepository.isAuthenticated(), false);
      expect(
        fakeRepository.loginCalls,
        contains('test@example.com:wrong-password'),
      );
    });

    test(
      'loginWithEmail should reject empty credentials when configured',
      () async {
        // Arrange
        fakeRepository.shouldRejectEmptyCredentials = true;

        // Act
        final result = await fakeRepository.loginWithEmail('', 'password');

        // Assert
        expect(result.isSuccess, false);
        expect(result.errorMessage, 'Email or password cannot be empty');
        expect(result.errorType, AuthErrorType.invalidCredentials);
      },
    );

    test(
      'registerWithEmail should succeed when configured to succeed',
      () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.registerWithEmail(
          'new@example.com',
          'password',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.email, 'new@example.com');
        expect(fakeRepository.isAuthenticated(), true);
        expect(
          fakeRepository.registerCalls,
          contains('new@example.com:password'),
        );
      },
    );

    test('logout should unauthenticate user and clear credentials', () async {
      // Arrange - start authenticated
      fakeRepository.fakeAuthResponse(succeed: true); // Ensure login call can succeed
      await fakeRepository.loginWithEmail('test@example.com', 'password');
      expect(fakeRepository.isAuthenticated(), true);

      // Act
      final result = await fakeRepository.logout();

      // Assert
      expect(result.isSuccess, true);
      expect(fakeRepository.isAuthenticated(), false);
      expect(fakeRepository.getCurrentCredentials(), isNull);
      expect(fakeRepository.logoutCalls, contains('logout'));
    });

    test('isAuthenticated should reflect current authentication state', () {
      // Start unauthenticated
      expect(fakeRepository.isAuthenticated(), false);

      // Create authenticated repository
      final authenticatedRepo = FakeAuthRepository(startAuthenticated: true);
      expect(authenticatedRepo.isAuthenticated(), true);
      authenticatedRepo.dispose();
    });
  });
} 