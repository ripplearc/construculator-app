// coverage:ignore-file

import 'package:construculator/libraries/supabase/data/supabase_types.dart';

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
      case SupabaseAuthErrorCode.unknown:
        return AuthErrorType.unknownError;
    }
  }
}

extension PostgresErrorCodeExtension on PostgresErrorCode {
  AuthErrorType toAuthErrorType() {
    switch (this) {
      case PostgresErrorCode.uniqueViolation:
        return AuthErrorType.invalidCredentials;
      case PostgresErrorCode.unableToConnect:
      case PostgresErrorCode.connectionFailure:
      case PostgresErrorCode.connectionDoesNotExist:
        return AuthErrorType.timeout;
      case PostgresErrorCode.unknownError:
        return AuthErrorType.unknownError;
    }
  }
}

/// Generic result class for authentication operations
class AuthResult<T> {
  /// The data returned from the operation
  final T? data;

  /// The error message returned from the operation
  final String? errorMessage;

  /// The type of error returned from the operation
  final AuthErrorType? errorType;

  /// Indicates if the operation was successful
  final bool isSuccess;

  AuthResult.success(this.data)
    : isSuccess = true,
      errorMessage = null,
      errorType = null;
  AuthResult.failure(this.errorMessage, this.errorType)
    : isSuccess = false,
      data = null;
}
