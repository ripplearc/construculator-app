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

  /// Select rows matching ALL entries in [filters] (multi-column equality).
  ///
  /// Equivalent to chaining multiple `.eq()` calls at the database level.
  /// Prefer this over [select] when filtering by more than one column to
  /// avoid fetching and filtering rows in memory.
  ///
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filters] Map of column → value pairs that must all match
  /// [orderBy] Optional column name to order results by
  /// [ascending] Sort direction when [orderBy] is provided, defaults to true
  Future<List<Map<String, dynamic>>> selectMatch({
    required String table,
    String columns = '*',
    required Map<String, dynamic> filters,
    String? orderBy,
    bool ascending = true,
  });

  /// Select a set of rows from a table where [filterColumn] value is in [filterValues].
  ///
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValues] The list of values to filter by using an `in` condition
  Future<List<Map<String, dynamic>>> selectWhereIn({
    required String table,
    String columns = '*',
    required String filterColumn,
    required List<dynamic> filterValues,
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

  /// Upsert a row into a table.
  ///
  /// Inserts the row, or updates it if a conflict occurs on [onConflict] columns.
  /// Requires a unique constraint on the [onConflict] columns in the database.
  ///
  /// [table] The table to upsert into
  /// [data] The data to insert or update
  /// [onConflict] Comma-separated column names for conflict detection (e.g. 'user_id,search_term,scope')
  Future<void> upsert({
    required String table,
    required Map<String, dynamic> data,
    required String onConflict,
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
  Future<void> delete({
    required String table,
    required String filterColumn,
    required dynamic filterValue,
  });

  /// Delete all rows from a table matching every entry in [filters].
  ///
  /// Prefer this over [delete] when deleting by a composite key, as it issues
  /// a single DELETE … WHERE rather than a select-then-loop approach.
  ///
  /// [table] The table to delete from
  /// [filters] Map of column → value pairs that must all match
  Future<void> deleteMatch({
    required String table,
    required Map<String, dynamic> filters,
  });

  /// Select a paginated set of rows from a table, ordered and ranged.
  ///
  /// [table] The table to select from
  /// [columns] The columns to select, defaults to '*'
  /// [filterColumn] The column to filter by
  /// [filterValue] The value to filter by
  /// [orderColumn] The column to order by
  /// [ascending] Whether to order ascending (default false = newest first)
  /// [rangeFrom] The starting index (inclusive, 0-based)
  /// [rangeTo] The ending index (inclusive, 0-based)
  Future<List<Map<String, dynamic>>> selectPaginated({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
    required String orderColumn,
    bool ascending = false,
    required int rangeFrom,
    required int rangeTo,
  });

  /// Watch all rows for a table in real-time.
  ///
  /// [primaryKey] must contain the table primary key columns.
  Stream<List<Map<String, dynamic>>> watchTable({
    required String table,
    required List<String> primaryKey,
  });

  /// Watch filtered table rows in real-time.
  ///
  /// [primaryKey] must contain the table primary key columns.
  Stream<List<Map<String, dynamic>>> watchTableFiltered({
    required String table,
    required List<String> primaryKey,
    required String filterColumn,
    required dynamic filterValue,
  });

  /// Call a Supabase RPC function
  ///
  /// [functionName] The name of the RPC function to call
  /// [params] The parameters to pass to the function
  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params});

  /// Get all permissions for a specific project from JWT claims
  ///
  /// Returns a list of permission keys (e.g., ['edit_cost_estimation', 'get_cost_estimations'])
  /// that the current user has for the specified project.
  ///
  /// Returns an empty list if:
  /// - User is not authenticated
  /// - User has no permissions for the project
  /// - Project ID not found in JWT claims
  ///
  /// [projectId] The UUID of the project
  List<String> getProjectPermissions(String projectId);

  /// Check if user has a specific permission for a project
  ///
  /// Convenience method that checks if [permissionKey] exists in the
  /// permissions list for [projectId] in the current user's JWT claims.
  ///
  /// [projectId] The UUID of the project
  /// [permissionKey] The permission key to check (e.g., 'edit_cost_estimation')
  bool hasProjectPermission(String projectId, String permissionKey);

  /// Refresh the current session to get updated JWT claims from the server
  ///
  /// **Important:** While Supabase automatically refreshes tokens before expiry,
  /// automatic refresh only extends token validity - it does NOT fetch updated
  /// claims from the server. This method forces a server-side refresh to get
  /// the latest JWT claims including updated permissions.
  ///
  /// Call this after operations that change user permissions:
  /// - Accepting project invitations
  /// - Role changes
  /// - Permission updates by admins
  ///
  /// Without manual refresh, permission changes remain invisible until the
  /// next natural token expiry (up to 1 hour).
  ///
  /// Throws [AuthException] if the refresh token has expired
  Future<void> refreshSession();

  /// Get the internal user ID from JWT claims
  ///
  /// Returns the application-layer user ID stored in JWT app_metadata,
  /// which differs from the authentication provider's user identifier.
  ///
  /// Returns null if user is not authenticated or internal_user_id is not set
  String? getInternalUserId();
}
