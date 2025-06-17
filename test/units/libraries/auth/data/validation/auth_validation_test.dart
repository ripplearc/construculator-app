import 'package:flutter_test/flutter_test.dart';
import 'package:construculator/libraries/auth/data/validation/auth_validation.dart';

void main() {
  group('AuthValidation', () {
    group('validateEmail', () {
      test('should return null for valid email addresses', () {
        expect(AuthValidation.validateEmail('test@example.com'), isNull);
        expect(AuthValidation.validateEmail('user.name@domain.co.uk'), isNull);
        expect(AuthValidation.validateEmail('user123@subdomain.domain.com'), isNull);
      });

      test('should return error message for null or empty email', () {
        expect(AuthValidation.validateEmail(null), 'Email is required');
        expect(AuthValidation.validateEmail(''), 'Email is required');
      });

      test('should return error message for invalid email addresses', () {
        expect(AuthValidation.validateEmail('test'), 'Please enter a valid email address');
        expect(AuthValidation.validateEmail('test@'), 'Please enter a valid email address');
        expect(AuthValidation.validateEmail('@domain.com'), 'Please enter a valid email address');
        expect(AuthValidation.validateEmail('test@domain'), 'Please enter a valid email address');
      });
    });

    group('validatePassword', () {
      test('should return null for valid passwords', () {
        expect(AuthValidation.validatePassword('Test123!@#'), isNull);
        expect(AuthValidation.validatePassword('StrongP@ss1'), isNull);
        expect(AuthValidation.validatePassword('C0mpl3x!Pass'), isNull);
      });

      test('should return error message for null or empty password', () {
        expect(AuthValidation.validatePassword(null), 'Password is required');
        expect(AuthValidation.validatePassword(''), 'Password is required');
      });

      test('should return error message for password less than 8 characters', () {
        expect(AuthValidation.validatePassword('Abc1!'), 'Password must be at least 8 characters long');
      });

      test('should return error message for password without uppercase letter', () {
        expect(AuthValidation.validatePassword('test123!@#'), 'Password must contain at least one uppercase letter');
      });

      test('should return error message for password without lowercase letter', () {
        expect(AuthValidation.validatePassword('TEST123!@#'), 'Password must contain at least one lowercase letter');
      });

      test('should return error message for password without number', () {
        expect(AuthValidation.validatePassword('TestPass!@#'), 'Password must contain at least one number');
      });

      test('should return error message for password without special character', () {
        expect(AuthValidation.validatePassword('TestPass123'), 'Password must contain at least one special character (!@#\$&*~)');
      });
    });

    group('validateOtp', () {
      test('should return null for valid OTP', () {
        expect(AuthValidation.validateOtp('123456'), isNull);
        expect(AuthValidation.validateOtp('000000'), isNull);
        expect(AuthValidation.validateOtp('999999'), isNull);
      });

      test('should return error message for null or empty OTP', () {
        expect(AuthValidation.validateOtp(null), 'OTP is required');
        expect(AuthValidation.validateOtp(''), 'OTP is required');
      });

      test('should return error message for invalid OTP', () {
        expect(AuthValidation.validateOtp('12345'), 'OTP must be exactly 6 digits');
        expect(AuthValidation.validateOtp('1234567'), 'OTP must be exactly 6 digits');
        expect(AuthValidation.validateOtp('12345a'), 'OTP must be exactly 6 digits');
        expect(AuthValidation.validateOtp('abc123'), 'OTP must be exactly 6 digits');
      });
    });

    group('validatePhone', () {
      test('should return null for valid phone numbers', () {
        expect(AuthValidation.validatePhone('+1234567890'), isNull);
        expect(AuthValidation.validatePhone('+44123456789'), isNull);
        expect(AuthValidation.validatePhone('+919876543210'), isNull);
      });

      test('should return error message for null or empty phone number', () {
        expect(AuthValidation.validatePhone(null), 'Phone number is required');
        expect(AuthValidation.validatePhone(''), 'Phone number is required');
      });

      test('should return error message for invalid phone numbers', () {
        expect(
          AuthValidation.validatePhone('1234567890'), 
          'Please enter a valid phone number in international format (e.g., +1234567890)'
        );
        expect(
          AuthValidation.validatePhone('abc1234567890'), 
          'Please enter a valid phone number in international format (e.g., +1234567890)'
        );
        expect(
          AuthValidation.validatePhone('+abc1234567890'), 
          'Please enter a valid phone number in international format (e.g., +1234567890)'
        );
      });
    });
  });
}
