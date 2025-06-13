import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface that abstracts authentication provider operations.
/// This allows the auth service to work with any authentication backend.
abstract class AuthRepository {
  /// Used to login a user with email and password
  // Future<AuthResult<UserCredential>> loginWithEmail(String email, String password);

  // /// Used to register a new user with email and password
  // Future<AuthResult<UserCredential>> registerWithEmail(String email, String password);

  // /// Used to send a 6-digit OTP (One-Time Password) to the specified email
  // Future<AuthResult<void>> sendOtp(String email, OtpReceiver receiver);

  // /// Used to verify an OTP code sent to an email
  // Future<AuthResult<UserCredential>> verifyOtp(String email, String otp, OtpReceiver receiver);

  // /// Used to send a password reset email to the user
  // Future<AuthResult<void>> resetPassword(String email);

  // /// Used to check if an email is registered with the authentication provider
  // Future<AuthResult<bool>> isEmailRegistered(String email);

  // /// Used to logout the current user
  // Future<AuthResult<void>> logout();

  // /// Used to check if the current user is authenticated
  // bool isAuthenticated();

  /// Used to get the current user's credentials
  UserCredential? getCurrentCredentials();

  /// Used to get the user profile
  Future<AuthResult<User>> getUserProfile(String credentialId);

  /// Used to create a new user profile
  Future<AuthResult<User>> createUserProfile(User user);

  /// Used to update the user profile
  Future<AuthResult<User>> updateUserProfile(User user);

  // /// Used to listen to authentication state changes
  // Stream<AuthStatus> get authStateChanges;

  // /// Used to listen to user changes
  // Stream<UserCredential?> get userChanges;
}