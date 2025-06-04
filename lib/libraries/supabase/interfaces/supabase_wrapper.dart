import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Interface that wraps Supabase client functionality
/// This allows for easier testing by providing a clean abstraction layer
abstract class SupabaseWrapper {
  // Auth-related methods
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