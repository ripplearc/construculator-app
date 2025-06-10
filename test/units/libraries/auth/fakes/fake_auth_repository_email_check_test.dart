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

  group('Email Registration Check', () {
    test(
      'isEmailRegistered should return true for registered emails',
      () async {
        // Arrange
        // The FakeAuthRepository has a default registered email: 'registered@example.com'
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.isEmailRegistered(
          'registered@example.com',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, true);
        expect(
          fakeRepository.emailCheckCalls,
          contains('registered@example.com'),
        );
      },
    );

    test(
      'isEmailRegistered should return false for unregistered emails',
      () async {
        // Arrange
        fakeRepository.fakeAuthResponse(succeed: true);

        // Act
        final result = await fakeRepository.isEmailRegistered(
          'unregistered@example.com',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, false);
        expect(
          fakeRepository.emailCheckCalls,
          contains('unregistered@example.com'),
        );
      },
    );

    test('isEmailRegistered should fail when configured to fail', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(
        succeed: false,
        errorMessage: 'Database unavailable',
      );

      // Act
      final result = await fakeRepository.isEmailRegistered(
        'any@example.com',
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Database unavailable');
      // The FakeAuthRepository sets AuthErrorType.serverError for general failures
      expect(result.errorType, AuthErrorType.serverError);
    });
  });
} 