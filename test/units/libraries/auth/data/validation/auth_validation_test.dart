import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('AuthValidation', () {
    group('validateEmail', () {
      test('should return null for valid email addresses', () {
        expect(AuthValidation.validateEmail('test@example.com'), isNull);
        expect(AuthValidation.validateEmail('user.name@domain.co.uk'), isNull);
        expect(AuthValidation.validateEmail('user123@subdomain.domain.com'), isNull);
      });

      test('should return error message for null or empty email', () {
        expect(AuthValidation.validateEmail(null), AuthValidationErrorType.emailRequired);
        expect(AuthValidation.validateEmail(''), AuthValidationErrorType.emailRequired);
      });

      test('should return error message for invalid email addresses', () {
        expect(AuthValidation.validateEmail('test'), AuthValidationErrorType.invalidEmail);
        expect(AuthValidation.validateEmail('test@'), AuthValidationErrorType.invalidEmail);
        expect(AuthValidation.validateEmail('@domain.com'), AuthValidationErrorType.invalidEmail);
        expect(AuthValidation.validateEmail('test@domain'), AuthValidationErrorType.invalidEmail);
      });
    });

    group('validatePassword', () {
      test('should return null for valid passwords', () {
        expect(AuthValidation.validatePassword('Test123!@#'), isNull);
        expect(AuthValidation.validatePassword('StrongP@ss1'), isNull);
        expect(AuthValidation.validatePassword('C0mpl3x!Pass'), isNull);
      });

      test('should return error message for null or empty password', () {
        expect(AuthValidation.validatePassword(null), AuthValidationErrorType.passwordRequired);
        expect(AuthValidation.validatePassword(''), AuthValidationErrorType.passwordRequired);
      });

      test('should return error message for password less than 8 characters', () {
        expect(AuthValidation.validatePassword('Abc1!'), AuthValidationErrorType.passwordTooShort);
      });

      test('should return error message for password without uppercase letter', () {
        expect(AuthValidation.validatePassword('test123!@#'), AuthValidationErrorType.passwordMissingUppercase);
      });

      test('should return error message for password without lowercase letter', () {
        expect(AuthValidation.validatePassword('TEST123!@#'), AuthValidationErrorType.passwordMissingLowercase);
      });

      test('should return error message for password without number', () {
        expect(AuthValidation.validatePassword('TestPass!@#'), AuthValidationErrorType.passwordMissingNumber);
      });

      test('should return error message for password without special character', () {
        expect(AuthValidation.validatePassword('TestPass123'), AuthValidationErrorType.passwordMissingSpecialChar);
      });
    });

    group('validateOtp', () {
      test('should return null for valid OTP', () {
        expect(AuthValidation.validateOtp('123456'), isNull);
        expect(AuthValidation.validateOtp('000000'), isNull);
        expect(AuthValidation.validateOtp('999999'), isNull);
      });

      test('should return error message for null or empty OTP', () {
        expect(AuthValidation.validateOtp(null), AuthValidationErrorType.otpRequired);
        expect(AuthValidation.validateOtp(''), AuthValidationErrorType.otpRequired);
      });

      test('should return error message for invalid OTP', () {
        expect(AuthValidation.validateOtp('12345'), AuthValidationErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('1234567'), AuthValidationErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('12345a'), AuthValidationErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('abc123'), AuthValidationErrorType.invalidOtp);
      });
    });

    group('validatePhoneNumber', () {
      test('should return null for valid phone numbers', () {
        expect(AuthValidation.validatePhoneNumber('+1234567890'), isNull);
        expect(AuthValidation.validatePhoneNumber('+44123456789'), isNull);
        expect(AuthValidation.validatePhoneNumber('+919876543210'), isNull);
      });

      test('should return error message for null or empty phone number', () {
        expect(AuthValidation.validatePhoneNumber(null), AuthValidationErrorType.phoneRequired);
        expect(AuthValidation.validatePhoneNumber(''), AuthValidationErrorType.phoneRequired);
      });

      test('should return error message for invalid phone numbers', () {
        expect(
          AuthValidation.validatePhoneNumber('1234567890'), 
          AuthValidationErrorType.invalidPhone
        );
        expect(
          AuthValidation.validatePhoneNumber('abc1234567890'), 
          AuthValidationErrorType.invalidPhone
        );
        expect(
          AuthValidation.validatePhoneNumber('+abc1234567890'), 
          AuthValidationErrorType.invalidPhone
        );
      });
    });
  });
}
