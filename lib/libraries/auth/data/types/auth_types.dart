enum AuthStatus { authenticated, unauthenticated, loading, connectionError }

enum OtpReceiver { email, phone }

enum UserProfileStatus { active, inactive }

// Much easier to manage errors with this enum
enum AuthErrorType{
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
  final T? data;
  final String? errorMessage;
  final AuthErrorType? errorType;
  final bool isSuccess;
  AuthResult.success(this.data) : isSuccess = true, errorMessage = null, errorType = null;
  AuthResult.failure(this.errorMessage, this.errorType) : isSuccess = false, data = null;
} 