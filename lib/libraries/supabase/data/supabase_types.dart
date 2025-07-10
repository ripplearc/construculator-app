// coverage:ignore-file

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

  @override
  String toString() {
    switch (this) {
      case PostgresErrorCode.uniqueViolation:
        return '23505';
      case PostgresErrorCode.unableToConnect:
        return '08001';
      case PostgresErrorCode.connectionFailure:
        return '08006';
      case PostgresErrorCode.connectionDoesNotExist:
        return '08003';
      case PostgresErrorCode.unknownError:
        return 'unknown';
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
}

/// Supabase auth error codes, grouped by error type
///
/// [invalidCredentials] corresponds to the error code invalid_credentials and is used when the credentials are invalid, eg. wrong email and password combination
/// [emailExists] corresponds to the error code email_exists and is used when the email already exists
/// [rateLimited] corresponds to the error code over_request_rate_limit and is used when the rate limit is exceeded, eg. when token is requested multiple times in a short period of time
/// [registrationFailure] corresponds to the error code signup_disabled and is used when user registration fails
/// [timeout] corresponds to the error code request_timeout and is used when the operation times out
/// [samePassword] corresponds to a user cedential update that uses the same password as the current one
/// [unknown] is used when the error is unknown
enum SupabaseAuthErrorCode {
  invalidCredentials,
  emailExists,
  rateLimited,
  registrationFailure,
  timeout,
  samePassword,
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

      case 'same_password':
        return SupabaseAuthErrorCode.samePassword;

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

  @override
  String toString() {
    switch (this) {
      case SupabaseAuthErrorCode.invalidCredentials:
        return 'invalid_credentials';
      case SupabaseAuthErrorCode.emailExists:
        return 'email_exists';
      case SupabaseAuthErrorCode.rateLimited:
        return 'over_request_rate_limit';
      case SupabaseAuthErrorCode.timeout:
        return 'request_timeout';
      case SupabaseAuthErrorCode.samePassword:
        return 'same_password';
      case SupabaseAuthErrorCode.registrationFailure:
        return 'signup_disabled';
      case SupabaseAuthErrorCode.unknown:
        return 'unknown';
    }
  }
}

enum SupabaseExceptionType { auth, postgrest, socket, timeout, type, unknown }
