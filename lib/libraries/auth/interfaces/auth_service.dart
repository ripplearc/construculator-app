import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/models/auth_user.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';

/// Interface for shared auth library, provides functionality for user authentication and basic profile management.
///
/// [loginWithEmail] is used to log in a user with email and password
/// [registerWithEmail] is used to register a new user with email and password
/// [sendOtp] is used to send a 6-digit OTP (One-Time Password) to the specified address
/// [verifyOtp] is used to verify an OTP code sent to an address
/// [resetPassword] is used to send a password reset email to the user
/// [isEmailRegistered] is used to check if an email is already registered
/// [logout] is used to log out the current user
/// [isAuthenticated] is used to check if a user is currently authenticated
/// [getUserInfo] is used to get the current user's profile information
/// [getCurrentUser] is used to get the current user's credentials
/// [authStateChanges] is used to listen to authentication state changes
abstract class AuthService {
  Future<bool> loginWithEmail(String email, String password);
  Future<bool> registerWithEmail(String email, String password);
  Future<bool> sendOtp(String address, OtpReceiver receiver);
  Future<bool> verifyOtp(String address, String otp, OtpReceiver receiver);
  Future<bool> resetPassword(String email);
  Future<bool> isEmailRegistered(String email);
  Future<void> logout();
  bool isAuthenticated();
  Future<User?> getUserInfo();
  Future<UserCredential?> getCurrentUser();
  Stream<AuthStatus> get authStateChanges;
}