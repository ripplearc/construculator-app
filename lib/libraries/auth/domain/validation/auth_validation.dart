import 'package:construculator/libraries/auth/domain/types/auth_types.dart';

/// Utility class for validating authentication inputs
class AuthValidation {
  // Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password validation regex patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#\$&*~]');

  // OTP validation regex pattern
  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  // Phone number validation regex pattern (international format)
  static final RegExp _phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');

  /// Validates an email address
  ///
  /// Returns an [AuthErrorType?] with an error type if validation fails, null otherwise
  static AuthErrorType? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return AuthErrorType.emailRequired;
    }

    if (!_emailRegex.hasMatch(email)) {
      return AuthErrorType.invalidEmail;
    }

    return null;
  }

  /// Validates a password
  ///
  /// Password requirements:
  /// - At least 8 characters long
  /// - Contains at least one uppercase letter
  /// - Contains at least one lowercase letter
  /// - Contains at least one number
  /// - Contains at least one special character (!@#$&*~)
  ///
  /// Returns an [AuthErrorType?] with an error type if validation fails, null otherwise
  static AuthErrorType? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AuthErrorType.passwordRequired;
    }

    if (password.length < 8) {
      return AuthErrorType.passwordTooShort;
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return AuthErrorType.passwordMissingUppercase;
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return AuthErrorType.passwordMissingLowercase;
    }

    if (!_numberRegex.hasMatch(password)) {
      return AuthErrorType.passwordMissingNumber;
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return AuthErrorType.passwordMissingSpecialChar;
    }

    return null;
  }

  /// Validates an OTP (One-Time Password)
  ///
  /// OTP requirements:
  /// - Must be exactly 6 digits
  ///
  /// Returns an [AuthErrorType?] with an error type if validation fails, null otherwise
  static AuthErrorType? validateOtp(String? otp) {
    if (otp == null || otp.isEmpty) {
      return AuthErrorType.otpRequired;
    }

    if (!_otpRegex.hasMatch(otp)) {
      return AuthErrorType.invalidOtp;
    }

    return null;
  }

  /// Validates a phone number
  ///
  /// Phone number requirements:
  /// - Must be in international format (+XXX...)
  /// - Must be between 8 and 15 digits (including country code)
  ///
  /// Returns an [AuthErrorType?] with an error type if validation fails, null otherwise
  static AuthErrorType? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return AuthErrorType.phoneRequired;
    }
    if (phone.length < 8 || phone.length > 15) {
      return AuthErrorType.invalidPhone;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      return AuthErrorType.invalidPhone;
    }

    return null;
  }
}
