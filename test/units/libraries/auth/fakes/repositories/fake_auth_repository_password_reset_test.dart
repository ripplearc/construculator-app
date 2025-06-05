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

  group('Password Reset Functionality', () {
    test('resetPassword should succeed when configured to succeed', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);

      // Act
      final result = await fakeRepository.resetPassword('test@example.com');

      // Assert
      expect(result.isSuccess, true);
      expect(fakeRepository.resetPasswordCalls, contains('test@example.com'));
    });

    test('resetPassword should fail when configured to fail', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Email service unavailable',
      );

      // Act
      final result = await fakeRepository.resetPassword('test@example.com');

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Email service unavailable');
      // The FakeAuthRepository sets AuthErrorType.serverError for general failures if not specified otherwise
      expect(result.errorType, AuthErrorType.serverError);
      expect(fakeRepository.resetPasswordCalls, contains('test@example.com'));
    });
  });
} 