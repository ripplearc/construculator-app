import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface for shared auth library, provides functionality 
/// for user authentication and basic profile management.
abstract class AuthManager {
  /// Logs in a user with email and password.
  /// 
  /// [email] - The email of the user.
  /// [password] - The password of the user.
  /// 
  /// Returns an [AuthResult] of [UserCredential] with the result of the login.
  Future<AuthResult<UserCredential>> loginWithEmail(String email, String password);

  /// Registers a new user with email and password.
  /// 
  /// [email] - The email of the user.
  /// [password] - The password of the user.
  /// 
  /// Returns an [AuthResult] of [UserCredential] with the result of the registration.
  Future<AuthResult<UserCredential>> registerWithEmail(String email, String password);

  /// Sends a 6-digit OTP (One-Time Password) to the specified address.
  /// 
  /// [address] - The address(email or phone) to send the OTP to.
  /// [receiver] - The receiver of the OTP of type [OtpReceiver].
  /// 
  /// Returns an [AuthResult] with the status of the OTP sending.
  Future<AuthResult> sendOtp(String address, OtpReceiver receiver);

  /// Verifies an OTP code sent to an address.
  /// 
  /// [address] - The address(email or phone) to send the OTP to.
  /// [otp] - The OTP code to verify.
  /// [receiver] - The receiver of the OTP of type [OtpReceiver].
  /// 
  /// Returns an [AuthResult] of [UserCredential] with the result of the OTP verification.
  Future<AuthResult<UserCredential>> verifyOtp(String address, String otp, OtpReceiver receiver);

  /// Sends a password reset email to the user.
  /// 
  /// [email] - The email of the user.
  /// 
  /// Returns a bool [AuthResult] with the result of the password reset.
  Future<bool> resetPassword(String email);

  /// Checks if an email is already registered.
  /// 
  /// [email] - The email of the user.
  /// 
  /// Returns a bool [AuthResult] with the result of the email registration check.
  Future<bool> isEmailRegistered(String email);

  /// Logs out the current user.
  Future<AuthResult<void>> logout();

  /// Checks if a user is currently authenticated.
  Future<AuthResult<bool>> isAuthenticated();

  /// Listens to authentication state changes.
  Stream<AuthStatus> get authStateChanges;
}