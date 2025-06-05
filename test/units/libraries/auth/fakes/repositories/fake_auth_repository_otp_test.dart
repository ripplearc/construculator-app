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

  group('OTP Functionality', () {
    test('sendOtp should succeed and generate OTP code', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);

      // Act
      final result = await fakeRepository.sendOtp(
        'test@example.com',
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(
        fakeRepository.sendOtpCalls,
        contains('test@example.com:OtpReceiver.email'),
      );
      expect(fakeRepository.getSentOtp('test@example.com'), isNotNull);
    });

    test('verifyOtp should succeed with correct OTP', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);
      await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
      final sentOtp = fakeRepository.getSentOtp('test@example.com')!;

      // Act
      final result = await fakeRepository.verifyOtp(
        'test@example.com',
        sentOtp,
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.email, 'test@example.com');
      expect(fakeRepository.isAuthenticated(), true);
      expect(
        fakeRepository.verifyOtpCalls,
        contains('test@example.com:$sentOtp:OtpReceiver.email'),
      );
    });

    test('verifyOtp should succeed with test OTP 123456', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);
      // Send an OTP first to set up the email in the system
      await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);

      // Act - use the special test OTP 123456
      final result = await fakeRepository.verifyOtp(
        'test@example.com',
        '123456',
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(fakeRepository.isAuthenticated(), true);
    });

    test('verifyOtp should fail with incorrect OTP', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true); // sendOtp should succeed
      await fakeRepository.sendOtp('test@example.com', OtpReceiver.email);
      // For verifyOtp to fail as expected, we set the response for that call.
      // The FakeAuthRepository internally sets the errorType based on the message or scenario.
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'Invalid OTP code');

      // Act
      final result = await fakeRepository.verifyOtp(
        'test@example.com',
        'wrong-otp',
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'Invalid OTP code');
      // We expect the repository to set this error type for invalid OTPs
      expect(result.errorType, AuthErrorType.invalidCredentials);
      expect(fakeRepository.isAuthenticated(), false);
    });

    test('verifyOtp should fail when no OTP was sent', () async {
      // Arrange
      // The FakeAuthRepository handles this specific error message and type.
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'No OTP was sent to this address');

      // Act
      final result = await fakeRepository.verifyOtp(
        'never-sent@example.com',
        '123456',
        OtpReceiver.email,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'No OTP was sent to this address');
      expect(result.errorType, AuthErrorType.invalidCredentials);
    });

    test('sendOtp should work with phone receiver', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);

      // Act
      final result = await fakeRepository.sendOtp(
        '+1234567890',
        OtpReceiver.phone,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(
        fakeRepository.sendOtpCalls,
        contains('+1234567890:OtpReceiver.phone'),
      );
      expect(fakeRepository.getSentOtp('+1234567890'), isNotNull);
    });

    test('verifyOtp should work with phone receiver', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true);
      const phoneNumber = '+1234567890';
      await fakeRepository.sendOtp(phoneNumber, OtpReceiver.phone);
      final sentOtp = fakeRepository.getSentOtp(phoneNumber)!;

      // Act
      final result = await fakeRepository.verifyOtp(
        phoneNumber,
        sentOtp,
        OtpReceiver.phone,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.metadata['receiver'], 'phone');
      expect(fakeRepository.isAuthenticated(), true);
      expect(
        fakeRepository.verifyOtpCalls,
        contains('$phoneNumber:$sentOtp:OtpReceiver.phone'),
      );
    });

    test('verifyOtp should fail when checking wrong receiver type', () async {
      // Arrange
      fakeRepository.fakeAuthResponse(succeed: true); // for sendOtp
      const address = 'test@example.com';
      await fakeRepository.sendOtp(address, OtpReceiver.email);

      // Configure verifyOtp to fail as if no OTP was sent to this type
      fakeRepository.fakeAuthResponse(succeed: false, errorMessage: 'No OTP was sent to this address');

      // Act - try to verify with phone receiver when it was sent to email
      final result = await fakeRepository.verifyOtp(
        address,
        '123456',
        OtpReceiver.phone,
      );

      // Assert
      expect(result.isSuccess, false);
      expect(result.errorMessage, 'No OTP was sent to this address');
      expect(result.errorType, AuthErrorType.invalidCredentials);
    });

    test('getSentOtp should support receiver-specific lookup', () async {
      // Arrange
      const address = 'test@example.com';
      fakeRepository.fakeAuthResponse(succeed: true);
      await fakeRepository.sendOtp(address, OtpReceiver.email);
      await fakeRepository.sendOtp(address, OtpReceiver.phone);

      // Act & Assert
      final emailOtp = fakeRepository.getSentOtp(address, OtpReceiver.email);
      final phoneOtp = fakeRepository.getSentOtp(address, OtpReceiver.phone);
      final anyOtp = fakeRepository.getSentOtp(
        address,
      ); // backward compatibility

      expect(emailOtp, isNotNull);
      expect(phoneOtp, isNotNull);
      expect(anyOtp, isNotNull);
      // They could be the same due to timing, but that's okay
      expect(emailOtp!.length, 6);
      expect(phoneOtp!.length, 6);
    });
  });
} 