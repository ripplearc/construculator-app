import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Interface that wraps Supabase client functionality
/// This allows for easier testing by providing a clean abstraction layer
/// Functions will grow as needed based on the project's requirements
/// 
/// [onAuthStateChange] is used to listen to authentication state changes
/// [currentUser] is used to get the current user
/// [isAuthenticated] is used to check if the current user is authenticated
/// [signInWithPassword] is used to sign in a user with email and password
/// [signUp] is used to sign up a new user with email and password
/// [signInWithOtp] is used as a means to send an OTP to the user's email or phone number
/// [verifyOTP] is used to verify an OTP code sent to an address
/// [resetPasswordForEmail] is used to send a password reset email to the user
/// [signOut] is used to sign out the current user
/// [selectSingle] is used to select a single row from a table
/// [insert] is used to insert a new row into a table
/// [update] is used to update an existing row in a table
abstract class SupabaseWrapper {
  Stream<supabase.AuthState> get onAuthStateChange;
  supabase.User? get currentUser;
  bool get isAuthenticated;
  
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
  
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  });
  
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  });
  
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  });
  
  Future<void> resetPasswordForEmail(String email, {String? redirectTo});
  
  Future<void> signOut();
  
  // Database-related methods
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  });
  
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  });
  
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  });
} 