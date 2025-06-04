import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface that abstracts authentication provider operations.
/// This allows the auth service to work with any authentication backend.
abstract class AuthRepository {
  /// Logs in a user with email and password
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password);

  /// Registers a new user with email and password
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password);
  
  /// Sends a 6-digit OTP (One-Time Password) to the specified email
  Future<AuthResult<void>> sendOtp(String email, OtpReceiver receiver);
  
  /// Verifies an OTP code sent to an email
  Future<AuthResult<UserCredential>> verifyOtp(String email, String otp, OtpReceiver receiver);
  
  /// Sends a password reset email to the user
  Future<AuthResult<void>> resetPassword(String email);

  /// Checks if an email is registered with the authentication provider
  Future<AuthResult<bool>> isEmailRegistered(String email);

  /// Logs out the current user
  Future<AuthResult<void>> logout();

  /// Checks if a user is currently authenticated
  bool isAuthenticated();

  /// Retrieves the current user's credentials
  UserCredential? getCurrentCredentials();

  /// Retrieves user data from the database using the current user's credentials
  Future<AuthResult<User>> getUserProfile(String credentialId);

  /// Creates a new user profile in the database
  Future<AuthResult<User>> createUserProfile(User user);

  /// Updates an existing user profile
  Future<AuthResult<User>> updateUserProfile(User user);

  /// Listens to authentication state changes
  Stream<AuthStatus> get authStateChanges;

  /// Listens to user profile updates
  Stream<UserCredential?> get userChanges;
}
