// coverage:ignore-file

import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:flutter/widgets.dart';

/// Tracks the authentication status of a user
///
/// [authenticated] is used when the user is authenticated
/// [unauthenticated] is used when the user is unauthenticated
/// [connectionError] is used when the connection to the server is lost
enum AuthStatus { authenticated, unauthenticated, connectionError }

/// The type of address an otp is sent to
///
/// [email] indicates the otp should be sent to an email
/// [phone] indicates the otp should be sent to a phone number
enum OtpReceiver { email, phone }

/// The user profile status
///
/// [active] indicates the user is active and mostly interracts with the platform
/// [inactive] indicates the user is inactive and likely left the platform
enum UserProfileStatus { active, inactive }

/// Error type for authentication operations
///
/// [userNotFound] is used when the user is not found
/// [invalidCredentials] is used when the credentials are invalid, eg. wrong email and password combination
/// [unknownError] is used when the error is unknown
/// [serverError] is used when the server is not responding or throws an error
/// [registrationFailure] is used when user registration fails
/// [networkError] is used when the network is not responding
/// [rateLimited] is used when the rate limit is exceeded, eg. when token is requested multiple times in a short period of time
/// [connectionError] is used when the connection to the server is lost
/// [timeout] is used when the operation times out
/// [emailRequired] is used when email is missing or empty
/// [invalidEmail] is used when email format is invalid
/// [passwordRequired] is used when password is missing or empty
/// [passwordTooShort] is used when password is less than 8 characters
/// [passwordMissingUppercase] is used when password lacks uppercase letters
/// [passwordMissingLowercase] is used when password lacks lowercase letters
/// [passwordMissingNumber] is used when password lacks numbers
/// [passwordMissingSpecialChar] is used when password lacks special characters
/// [passwordsDoNotMatch] is used when passwords do not match
/// [roleRequired] is used when role is missing or empty
/// [firstNameRequired] is used when first name is missing or empty
/// [lastNameRequired] is used when last name is missing or empty
/// [otpRequired] is used when OTP is missing or empty
/// [invalidOtp] is used when OTP format is invalid
/// [phoneRequired] is used when phone number is missing or empty
/// [invalidPhone] is used when phone number format is invalid
/// [samePassword] is used when new password is same as current password
enum AuthErrorType {
  userNotFound,
  invalidCredentials,
  unknownError,
  serverError,
  registrationFailure,
  networkError,
  rateLimited,
  connectionError,
  timeout,
  emailRequired,
  invalidEmail,
  passwordRequired,
  passwordTooShort,
  passwordMissingUppercase,
  passwordMissingLowercase,
  passwordMissingNumber,
  passwordMissingSpecialChar,
  passwordsDoNotMatch,
  roleRequired,
  firstNameRequired,
  lastNameRequired,
  otpRequired,
  invalidOtp,
  phoneRequired,
  invalidPhone,
  uniqueViolation,
  samePassword,
}

extension AuthErrorTypeExtension on AuthErrorType {
  String? localizedMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case AuthErrorType.userNotFound:
        return l10n?.userNotFoundError;
      case AuthErrorType.invalidCredentials:
        return l10n?.invalidCredentialsError;
      case AuthErrorType.unknownError:
        return l10n?.unknownError;
      case AuthErrorType.serverError:
        return l10n?.serverError;
      case AuthErrorType.registrationFailure:
        return l10n?.registrationFailedError;
      case AuthErrorType.networkError:
        return l10n?.networkError;
      case AuthErrorType.rateLimited:
        return l10n?.rateLimitError;
      case AuthErrorType.connectionError:
        return l10n?.connectionError;
      case AuthErrorType.timeout:
        return l10n?.timeoutError;
      case AuthErrorType.emailRequired:
        return l10n?.emailRequiredError;
      case AuthErrorType.invalidEmail:
        return l10n?.invalidEmailError;
      case AuthErrorType.passwordRequired:
        return l10n?.passwordRequiredError;
      case AuthErrorType.passwordTooShort:
        return l10n?.passwordTooShortError;
      case AuthErrorType.passwordMissingUppercase:
        return l10n?.passwordMissingUppercaseError;
      case AuthErrorType.passwordMissingLowercase:
        return l10n?.passwordMissingLowercaseError;
      case AuthErrorType.passwordMissingNumber:
        return l10n?.passwordMissingNumberError;
      case AuthErrorType.passwordMissingSpecialChar:
        return l10n?.passwordMissingSpecialCharError;
      case AuthErrorType.passwordsDoNotMatch:
        return l10n?.passwordsDoNotMatchError;
      case AuthErrorType.roleRequired:
        return l10n?.roleRequiredError;
      case AuthErrorType.firstNameRequired:
        return l10n?.firstNameRequired;
      case AuthErrorType.lastNameRequired:
        return l10n?.lastNameRequired;
      case AuthErrorType.otpRequired:
        return l10n?.otpRequiredError;
      case AuthErrorType.invalidOtp:
        return l10n?.invalidOtpError;
      case AuthErrorType.phoneRequired:
        return l10n?.phoneRequiredError;
      case AuthErrorType.invalidPhone:
        return l10n?.invalidPhoneError;
      case AuthErrorType.uniqueViolation:
        return l10n?.duplicateErrorMessage;
      case AuthErrorType.samePassword:
        return l10n?.samePasswordErrorMessage;
    }
  }
}

extension SupabaseAuthErrorCodeExtension on SupabaseAuthErrorCode {
  AuthErrorType toAuthErrorType() {
    switch (this) {
      case SupabaseAuthErrorCode.invalidCredentials:
        return AuthErrorType.invalidCredentials;
      case SupabaseAuthErrorCode.emailExists:
      case SupabaseAuthErrorCode.registrationFailure:
        return AuthErrorType.registrationFailure;
      case SupabaseAuthErrorCode.rateLimited:
        return AuthErrorType.rateLimited;
      case SupabaseAuthErrorCode.timeout:
        return AuthErrorType.timeout;
      case SupabaseAuthErrorCode.samePassword:
        return AuthErrorType.samePassword;
      case SupabaseAuthErrorCode.unknown:
        return AuthErrorType.unknownError;
    }
  }
}

extension PostgresErrorCodeExtension on PostgresErrorCode {
  AuthErrorType toAuthErrorType() {
    switch (this) {
      case PostgresErrorCode.uniqueViolation:
        return AuthErrorType.uniqueViolation;
      case PostgresErrorCode.unableToConnect:
      case PostgresErrorCode.connectionFailure:
      case PostgresErrorCode.connectionDoesNotExist:
        return AuthErrorType.timeout;
      case PostgresErrorCode.unknownError:
        return AuthErrorType.unknownError;
      default:
        return AuthErrorType.unknownError;
    }
  }
}

/// Generic result class for authentication operations
class AuthResult<T> {
  /// The data returned from the operation
  final T? data;

  /// The type of error returned from the operation
  final AuthErrorType? errorType;

  /// Indicates if the operation was successful
  final bool isSuccess;

  AuthResult.success(this.data) : isSuccess = true, errorType = null;
  AuthResult.failure(this.errorType) : isSuccess = false, data = null;
}
