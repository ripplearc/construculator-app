/// Utility class for validating authentication inputs
class AuthValidationUtils {
  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation regex patterns
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp _numberRegex = RegExp(r'[0-9]');
  static final RegExp _specialCharRegex = RegExp(r'[!@#\$&*~]');

  /// OTP validation regex pattern
  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  /// Phone number validation regex pattern (international format)
  static final RegExp _phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');

  /// Validates an email address
  /// 
  /// Returns a [String?] with an error message if validation fails, null otherwise
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }

    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
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
  /// Returns a [String?] with an error message if validation fails, null otherwise
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!_uppercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!_lowercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!_numberRegex.hasMatch(password)) {
      return 'Password must contain at least one number';
    }

    if (!_specialCharRegex.hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$&*~)';
    }

    return null;
  }

  /// Validates an OTP (One-Time Password)
  /// 
  /// OTP requirements:
  /// - Must be exactly 6 digits
  /// 
  /// Returns a [String?] with an error message if validation fails, null otherwise
  static String? validateOtp(String? otp) {
    if (otp == null || otp.isEmpty) {
      return 'OTP is required';
    }

    if (!_otpRegex.hasMatch(otp)) {
      return 'OTP must be exactly 6 digits';
    }

    return null;
  }

  /// Validates a phone number
  /// 
  /// Phone number requirements:
  /// - Must be in international format (+XXX...)
  /// - Must be between 8 and 15 digits (including country code)
  /// 
  /// Returns a [String?] with an error message if validation fails, null otherwise
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }

    if (!_phoneRegex.hasMatch(phone)) {
      return 'Please enter a valid phone number in international format (e.g., +1234567890)';
    }

    return null;
  }
} 