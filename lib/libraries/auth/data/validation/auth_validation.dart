import 'package:construculator/libraries/auth/data/types/auth_types.dart';

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
  /// Returns an [AuthValidationErrorType?] with an error type if validation fails, null otherwise
  static AuthValidationErrorType? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return AuthValidationErrorType.emailRequired;
    }

    if (!_emailRegex.hasMatch(email)) {
      return AuthValidationErrorType.invalidEmail;
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
  /// Returns an [AuthValidationErrorType?] with an error type if validation fails, null otherwise
  static AuthValidationErrorType? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return AuthValidationErrorType.passwordRequired;
    }

    if (password.length < 8) {
      return AuthValidationErrorType.passwordTooShort;
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return AuthValidationErrorType.passwordMissingUppercase;
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return AuthValidationErrorType.passwordMissingLowercase;
    }

    if (!_numberRegex.hasMatch(password)) {
      return AuthValidationErrorType.passwordMissingNumber;
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return AuthValidationErrorType.passwordMissingSpecialChar;
    }

    return null;
  }

  /// Validates an OTP (One-Time Password)
  /// 
  /// OTP requirements:
  /// - Must be exactly 6 digits
  /// 
  /// Returns an [AuthValidationErrorType?] with an error type if validation fails, null otherwise
  static AuthValidationErrorType? validateOtp(String? otp) {
    if (otp == null || otp.isEmpty) {
      return AuthValidationErrorType.otpRequired;
    }

    if (!_otpRegex.hasMatch(otp)) {
      return AuthValidationErrorType.invalidOtp;
    }

    return null;
  }

  /// Validates a phone number
  /// 
  /// Phone number requirements:
  /// - Must be in international format (+XXX...)
  /// - Must be between 8 and 15 digits (including country code)
  /// 
  /// Returns an [AuthValidationErrorType?] with an error type if validation fails, null otherwise
  static AuthValidationErrorType? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return AuthValidationErrorType.phoneRequired;
    }

    if (!_phoneRegex.hasMatch(phone)) {
      return AuthValidationErrorType.invalidPhone;
    }

    return null;
  }
} 