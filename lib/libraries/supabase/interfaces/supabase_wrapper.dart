import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Interface that wraps Supabase client functionality
/// This allows for easier testing by providing a clean abstraction layer
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
/// Functions will grow as needed based on the project's requirements
abstract class SupabaseWrapper {
  /// Streams authentication state changes
<<<<<<< HEAD
  Stream<supabase.AuthState> get onAuthStateChange;
  
  supabase.User? get currentUser;

  bool get isAuthenticated;
  
  /// Initialize the Supabase client
  /// 
  /// throws [ClientException] if the supabase url or anon key is not set
  Future<void> initialize();

  /// Sign in a user with email and password
  /// 
  /// [email] The email of the user
  /// [password] The password of the user
=======
abstract class ISupabaseWrapper {
=======
abstract class SupabaseWrapper {
>>>>>>> 5b674ca (Refactor supabase library to be more consistent with conventions)
  // Auth-related methods
=======
/// Functions will grow as needed based on the project's requirements
abstract class SupabaseWrapper {
>>>>>>> 3915f4d (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Stream<supabase.AuthState> get onAuthStateChange;
  
  supabase.User? get currentUser;

  bool get isAuthenticated;
  
<<<<<<< HEAD
>>>>>>> 5777a70 (Fix restack errors)
=======
  /// Initialize the Supabase client
  Future<void> initialize();

  /// Sign in a user with email and password
  /// 
  /// [email] The email of the user
  /// [password] The password of the user
>>>>>>> 0836451 (Fix restack errors)
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)

  /// Sign up a new user with email and password
  /// 
  /// [email] The email of the user
  /// [password] The password of the user
<<<<<<< HEAD
=======
  
>>>>>>> 5777a70 (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  });
  
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)
  /// Sign in a user with an OTP/Used in this app for the purposes of sending OTPs
  /// 
  /// [email] The email of the user
  /// [phone] The phone number of the user
  /// [shouldCreateUser] Whether to create the user if they don't exist
<<<<<<< HEAD
=======
>>>>>>> 5777a70 (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  });
  
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)
  /// Verify an OTP sent to an email or phone
  /// 
  /// [email] The email of the user
  /// [phone] The phone number of the user
  /// [token] The OTP token, in this case a 6 digit number
  /// [type] The type of OTP, in this case 'email' or 'sms', refer [supabase.OtpType]
<<<<<<< HEAD
=======
>>>>>>> 5777a70 (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  });
  
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)
  /// Reset a user's password for email
  /// 
  /// [email] The email of the user
  /// [redirectTo] The URL to redirect to after password reset, 
  /// this is currently not used in the app
<<<<<<< HEAD
  Future<void> resetPasswordForEmail(String email, {String? redirectTo});
  
  /// Sign out the current user
  Future<void> signOut();
  
  // Database-related methods
  /// Select a single row from a table
  /// 
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
=======
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<void> resetPasswordForEmail(String email, {String? redirectTo});
  
  /// Sign out the current user
  Future<void> signOut();
  
  // Database-related methods
<<<<<<< HEAD
>>>>>>> 5777a70 (Fix restack errors)
=======
  /// Select a single row from a table
  /// 
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
>>>>>>> 0836451 (Fix restack errors)
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  });
  
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)
  /// Insert a row into a table
  /// 
  /// [table] The table to insert into
  /// [data] The data to insert, [Map]
<<<<<<< HEAD
=======
>>>>>>> 5777a70 (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  });
  
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors)
  /// Update a row in a table
  /// 
  /// [table] The table to update
  /// [data] The data to update, [Map]
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
<<<<<<< HEAD
=======
>>>>>>> 5777a70 (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors)
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  });
} 