import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface for shared auth library, provides functionality for user 
/// authentication and basic profile management.
abstract class AuthService {
  /// Logs in a user with email and password.
  /// 
  /// [email] - The email of the user.
  /// [password] - The password of the user.
  /// 
  /// Returns a bool [AuthResult] with the result of the login.
  Future<AuthResult<bool>> loginWithEmail(String email, String password);

  /// Registers a new user with email and password.
  Future<bool> registerWithEmail(String email, String password);

  /// Sends a 6-digit OTP (One-Time Password) to the specified address.
  Future<bool> sendOtp(String address, OtpReceiver receiver);

  /// Verifies an OTP code sent to an address.
  Future<bool> verifyOtp(String address, String otp, OtpReceiver receiver);

  /// Sends a password reset email to the user.
  Future<bool> resetPassword(String email);

  /// Checks if an email is already registered.
  Future<bool> isEmailRegistered(String email);

  /// Logs out the current user.
  Future<void> logout();

  /// Checks if a user is currently authenticated.
  bool isAuthenticated();
}