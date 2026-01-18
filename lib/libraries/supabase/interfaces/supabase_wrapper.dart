import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Interface that wraps Supabase client functionality
/// This allows for easier testing by providing a clean abstraction layer
/// Functions will grow as needed based on the project's requirements
abstract class SupabaseWrapper {
  /// Streams authentication state changes
  Stream<supabase.AuthState> get onAuthStateChange;

  /// The current user
  supabase.User? get currentUser;

  /// Whether the user is authenticated
  bool get isAuthenticated;

  /// Initialize the Supabase client
  ///
  /// throws [ClientException] if the supabase url or anon key is not set
  Future<void> initialize();

  /// Sign in a user with email and password
  ///
  /// [email] The email of the user
  /// [password] The password of the user
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  /// Sign up a new user with email and password
  ///
  /// [email] The email of the user
  /// [password] The password of the user
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  });

  /// Sign in a user with an OTP/Used in this app for the purposes of sending OTPs
  ///
  /// [email] The email of the user
  /// [phone] The phone number of the user
  /// [shouldCreateUser] Whether to create the user if they don't exist
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  });

  /// Verify an OTP sent to an email or phone
  ///
  /// [email] The email of the user
  /// [phone] The phone number of the user
  /// [token] The OTP token, in this case a 6 digit number
  /// [type] The type of OTP, in this case 'email' or 'sms', refer [supabase.OtpType]
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  });

  /// Reset a user's password for email
  ///
  /// [email] The email of the user
  /// [redirectTo] The URL to redirect to after password reset,
  /// this is currently not used in the app
  Future<void> resetPasswordForEmail(String email, {String? redirectTo});

  /// Sign out the current user
  Future<void> signOut();

  /// Select a set of rows from a table
  ///
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  });

  // Database-related methods
  /// Select a single row from a table
  ///
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  });

  /// Select all professional roles from the database
  Future<List<Map<String, dynamic>>> selectAllProfessionalRoles();

  /// Insert a row into a table
  ///
  /// [table] The table to insert into
  /// [data] The data to insert, [Map]
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  });

  /// Update a row in a table
  ///
  /// [table] The table to update
  /// [data] The data to update, [Map]
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  });

  /// Update supabase user,can be used to update the user's email as well as password.
  ///
  /// [userAttributes] The user details to update, this is the [supabase.UserAttributes] object from the supabase client
  Future<supabase.UserResponse> updateUser(
    supabase.UserAttributes userAttributes,
  );

  /// Delete a row from a table
  ///
  /// [table] The table to delete from
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
  Future<Map<String, dynamic>> delete({
    required String table,
    required String filterColumn,
    required dynamic filterValue,
  });

  /// Call a Supabase RPC function
  ///
  /// [functionName] The name of the RPC function to call
  /// [params] The parameters to pass to the function
  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params});
}
