// coverage:ignore-file

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

/// Postgres error codes
/// 
/// [uniqueViolation] corresponds to the error code 23505 and is used when a unique constraint is violated
/// [unableToConnect] corresponds to the error code 08001 and is used when the connection to the server is lost
/// [connectionFailure] corresponds to the error code 08006 and is used when the connection to the server is lost
/// [connectionDoesNotExist] corresponds to the error code 08003 and is used when the connection to the server is lost
/// [unknownError] is used when the error is unknown
enum PostgresErrorCode {
  uniqueViolation,
  unableToConnect,
  connectionFailure,
  connectionDoesNotExist,
  unknownError;

  static PostgresErrorCode fromCode(String? code) {
    switch (code) {
      case '23505':
        return PostgresErrorCode.uniqueViolation;
      case '08001':
        return PostgresErrorCode.unableToConnect;
      case '08006':
        return PostgresErrorCode.connectionFailure;
      case '08003':
        return PostgresErrorCode.connectionDoesNotExist;
      default:
        return PostgresErrorCode.unknownError;
    }
  }

  String get message {
    switch (this) {
      case PostgresErrorCode.uniqueViolation:
        return 'This value already exists.';
      case PostgresErrorCode.unableToConnect:
        return 'Unable to connect to the database.';
      case PostgresErrorCode.connectionFailure:
        return 'The database connection was lost.';
      case PostgresErrorCode.connectionDoesNotExist:
        return 'No existing database connection found.';
      case PostgresErrorCode.unknownError:
        return 'An unknown database error occurred.';
    }
  }

  AuthErrorType get errorType {
    switch (this) {
      case PostgresErrorCode.uniqueViolation:
        return AuthErrorType.invalidCredentials; // or maybe registrationFailure?
      case PostgresErrorCode.unableToConnect:
      case PostgresErrorCode.connectionFailure:
      case PostgresErrorCode.connectionDoesNotExist:
        return AuthErrorType.timeout;
      case PostgresErrorCode.unknownError:
        return AuthErrorType.unknownError;
    }
  }
}

/// Supabase auth error codes
/// 
/// [invalidCredentials] corresponds to the error code invalid_credentials and is used when the credentials are invalid, eg. wrong email and password combination
/// [emailExists] corresponds to the error code email_exists and is used when the email already exists
/// [rateLimited] corresponds to the error code over_request_rate_limit and is used when the rate limit is exceeded, eg. when token is requested multiple times in a short period of time
/// [registrationFailure] corresponds to the error code signup_disabled and is used when user registration fails
/// [timeout] corresponds to the error code request_timeout and is used when the operation times out
/// [unknown] is used when the error is unknown
enum SupabaseAuthErrorCode {
  invalidCredentials,
  emailExists,
  rateLimited,
  registrationFailure,
  timeout,
  unknown;

  static SupabaseAuthErrorCode fromCode(String code) {
    switch (code) {
      case 'invalid_credentials':
      case 'email_address_invalid':
      case 'weak_password':
      case 'user_not_found':
      case 'email_not_confirmed':
      case 'session_expired':
      case 'session_not_found':
      case 'refresh_token_not_found':
      case 'refresh_token_already_used':
      case 'otp_expired':
      case 'bad_jwt':
      case 'no_authorization':
        return SupabaseAuthErrorCode.invalidCredentials;

      case 'email_exists':
      case 'user_already_exists':
        return SupabaseAuthErrorCode.emailExists;

      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
      case 'over_sms_send_rate_limit':
        return SupabaseAuthErrorCode.rateLimited;

      case 'signup_disabled':
      case 'email_provider_disabled':
      case 'phone_provider_disabled':
        return SupabaseAuthErrorCode.registrationFailure;

      case 'request_timeout':
        return SupabaseAuthErrorCode.timeout;

      default:
        return SupabaseAuthErrorCode.unknown;
    }
  }

  String get message {
    switch (this) {
      case SupabaseAuthErrorCode.invalidCredentials:
        return 'Invalid email or password';
      case SupabaseAuthErrorCode.emailExists:
        return 'Email already exists';
      case SupabaseAuthErrorCode.rateLimited:
        return 'Too many attempts. Please try again later.';
      case SupabaseAuthErrorCode.registrationFailure:
        return 'Registration is currently disabled';
      case SupabaseAuthErrorCode.timeout:
        return 'Request timed out. Please try again.';
      case SupabaseAuthErrorCode.unknown:
        return 'An unknown error occurred';
    }
  }

  AuthErrorType get errorType {
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

/// Much easier to manage errors with this enum
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
