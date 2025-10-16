import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

void main() {
  group('AuthValidation', () {
    group('validateEmail', () {
      test('should return null for valid email addresses', () {
        expect(AuthValidation.validateEmail('test@example.com'), isNull);
        expect(AuthValidation.validateEmail('user.name@domain.co.uk'), isNull);
        expect(
          AuthValidation.validateEmail('user123@subdomain.domain.com'),
          isNull,
        );
      });

      test('should return error message for null or empty email', () {
        expect(AuthValidation.validateEmail(null), AuthErrorType.emailRequired);
        expect(AuthValidation.validateEmail(''), AuthErrorType.emailRequired);
      });

      test('should return error message for invalid email addresses', () {
        expect(
          AuthValidation.validateEmail('test'),
          AuthErrorType.invalidEmail,
        );
        expect(
          AuthValidation.validateEmail('test@'),
          AuthErrorType.invalidEmail,
        );
        expect(
          AuthValidation.validateEmail('@domain.com'),
          AuthErrorType.invalidEmail,
        );
        expect(
          AuthValidation.validateEmail('test@domain'),
          AuthErrorType.invalidEmail,
        );
      });
    });

    group('validatePassword', () {
      test('should return null for valid passwords', () {
        expect(AuthValidation.validatePassword('Test123!@#'), isNull);
        expect(AuthValidation.validatePassword('StrongP@ss1'), isNull);
        expect(AuthValidation.validatePassword('C0mpl3x!Pass'), isNull);
      });

      test('should return error message for null or empty password', () {
        expect(
          AuthValidation.validatePassword(null),
          AuthErrorType.passwordRequired,
        );
        expect(
          AuthValidation.validatePassword(''),
          AuthErrorType.passwordRequired,
        );
      });

      test(
        'should return error message for password less than 8 characters',
        () {
          expect(
            AuthValidation.validatePassword('Abc1!'),
            AuthErrorType.passwordTooShort,
          );
        },
      );

      test(
        'should return error message for password without uppercase letter',
        () {
          expect(
            AuthValidation.validatePassword('test123!@#'),
            AuthErrorType.passwordMissingUppercase,
          );
        },
      );

      test(
        'should return error message for password without lowercase letter',
        () {
          expect(
            AuthValidation.validatePassword('TEST123!@#'),
            AuthErrorType.passwordMissingLowercase,
          );
        },
      );

      test('should return error message for password without number', () {
        expect(
          AuthValidation.validatePassword('TestPass!@#'),
          AuthErrorType.passwordMissingNumber,
        );
      });

      test(
        'should return error message for password without special character',
        () {
          expect(
            AuthValidation.validatePassword('TestPass123'),
            AuthErrorType.passwordMissingSpecialChar,
          );
        },
      );
    });

    group('validateOtp', () {
      test('should return null for valid OTP', () {
        expect(AuthValidation.validateOtp('123456'), isNull);
        expect(AuthValidation.validateOtp('000000'), isNull);
        expect(AuthValidation.validateOtp('999999'), isNull);
      });

      test('should return error message for null or empty OTP', () {
        expect(AuthValidation.validateOtp(null), AuthErrorType.otpRequired);
        expect(AuthValidation.validateOtp(''), AuthErrorType.otpRequired);
      });

      test('should return error message for invalid OTP', () {
        expect(AuthValidation.validateOtp('12345'), AuthErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('1234567'), AuthErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('12345a'), AuthErrorType.invalidOtp);
        expect(AuthValidation.validateOtp('abc123'), AuthErrorType.invalidOtp);
      });
    });

    group('validatePhoneNumber', () {
      test('should return null for valid phone numbers', () {
        expect(AuthValidation.validatePhoneNumber('+1234567890'), isNull);
        expect(AuthValidation.validatePhoneNumber('+44123456789'), isNull);
        expect(AuthValidation.validatePhoneNumber('+919876543210'), isNull);
      });

      test('should return error message for null or empty phone number', () {
        expect(
          AuthValidation.validatePhoneNumber(null),
          AuthErrorType.phoneRequired,
        );
        expect(
          AuthValidation.validatePhoneNumber(''),
          AuthErrorType.phoneRequired,
        );
      });

      test('should return error message for invalid phone numbers', () {
        expect(
          AuthValidation.validatePhoneNumber('+1234'),
          AuthErrorType.invalidPhone,
        );
        expect(
          AuthValidation.validatePhoneNumber('+12349029398384747473746'),
          AuthErrorType.invalidPhone,
        );
        expect(
          AuthValidation.validatePhoneNumber('1234567890'),
          AuthErrorType.invalidPhone,
        );
        expect(
          AuthValidation.validatePhoneNumber('abc1234567890'),
          AuthErrorType.invalidPhone,
        );
        expect(
          AuthValidation.validatePhoneNumber('+abc1234567890'),
          AuthErrorType.invalidPhone,
        );
      });
    });
  });
}
