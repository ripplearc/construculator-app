import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface that abstracts authentication provider operations.
/// This allows the auth service to work with any authentication backend.
///
/// [loginWithEmail] is used to login a user with email and password
/// [registerWithEmail] is used to register a new user with email and password
/// [sendOtp] is used to send a 6-digit OTP (One-Time Password) to the specified email
/// [verifyOtp] is used to verify an OTP code sent to an email
/// [resetPassword] is used to send a password reset email to the user
/// [isEmailRegistered] is used to check if an email is registered with the authentication provider
/// [logout] is used to logout the current user
/// [isAuthenticated] is used to check if the current user is authenticated
/// [getCurrentCredentials] is used to get the current user's credentials
/// [getUserProfile] is used to get the user's profile
/// [createUserProfile] is used to create a new user profile
/// [updateUserProfile] is used to update the user's profile
/// [authStateChanges] is used to listen to authentication state changes
/// [userChanges] is used to listen to user changes
abstract class AuthRepository {
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password);
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password);
  Future<AuthResult<void>> sendOtp(String email, OtpReceiver receiver);
  Future<AuthResult<UserCredential>> verifyOtp(String email, String otp, OtpReceiver receiver);
  Future<AuthResult<void>> resetPassword(String email);
  Future<AuthResult<bool>> isEmailRegistered(String email);
  Future<AuthResult<void>> logout();
  bool isAuthenticated();
  UserCredential? getCurrentCredentials();
  Future<AuthResult<User>> getUserProfile(String credentialId);
  Future<AuthResult<User>> createUserProfile(User user);
  Future<AuthResult<User>> updateUserProfile(User user);
  Stream<AuthStatus> get authStateChanges;
  Stream<UserCredential?> get userChanges;
}
