import 'package:construculator/libraries/auth/data/models/auth_credential.dart';
import 'package:construculator/libraries/auth/data/types/auth_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class IAuthService {
  /// Log in a user with email and password
  Future<bool> loginWithEmail(String email, String password);
  
  /// Register a new user with email and password
  Future<bool> registerWithEmail(String email, String password);
  
  /// Send a 6-digit OTP (One-Time Password) to the specified address
  Future<bool> sendOtp(String address, OtpReceiver receiver);
  
  /// Verify an OTP code sent to an address
  Future<bool> verifyOtp(String address, String otp, OtpReceiver receiver);
  
  /// Send a password reset email to the user
  Future<bool> resetPassword(String email);
  
  /// Check if an email is already registered
  Future<bool> isEmailRegistered(String email);
  
  /// Log out the current user
  Future<void> logout();
  
  /// Check if a user is currently authenticated
  bool isAuthenticated();
  
  /// Get the current user's profile information
  Future<User?> getUserInfo();
  
  /// Get the current user's authentication credentials
  Future<UserCredential?> getCurrentUser();
  
  /// Stream of authentication state changes
  Stream<AuthStatus> get authStateChanges;
} 