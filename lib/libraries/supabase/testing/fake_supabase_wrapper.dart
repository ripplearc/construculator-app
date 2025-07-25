import 'dart:async';
import 'dart:io';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_state.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Fake implementation of SupabaseWrapper for testing
class FakeSupabaseWrapper implements SupabaseWrapper {
  /// Used to notify listeners of changes in the authentication state through [onAuthStateChange]
  final StreamController<supabase.AuthState> _authStateController =
      StreamController<supabase.AuthState>.broadcast();

  /// Tracks the currently authenticated user
  FakeUser? _currentUser;

  /// Tracks table data for assertions during [selectSingle], [insert], and [update]
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Controls whether [signInWithPassword] throws an exception
  bool shouldThrowOnSignIn = false;

  /// Controls whether [signUp] throws an exception
  bool shouldThrowOnSignUp = false;

  /// Controls whether [signInWithOtp] throws an exception
  bool shouldThrowOnOtp = false;

  /// Controls whether [verifyOTP] throws an exception
  bool shouldThrowOnVerifyOtp = false;

  /// Controls whether [resetPasswordForEmail] throws an exception
  bool shouldThrowOnResetPassword = false;

  /// Controls whether [signOut] throws an exception
  bool shouldThrowOnSignOut = false;

  /// Controls whether [selectSingle] throws an exception
  bool shouldThrowOnSelect = false;

  /// Controls whether [insert] throws an exception
  bool shouldThrowOnInsert = false;

  /// Controls whether [update] throws an exception
  bool shouldThrowOnUpdate = false;

  /// Error message for sign in.
  /// Used to specify the error message thrown when [signInWithPassword] is attempted
  String? signInErrorMessage;

  /// Error message for sign up.
  /// Used to specify the error message thrown when [signUp] is attempted
  String? signUpErrorMessage;

  /// Error message for OTP.
  /// Used to specify the error message thrown when [signInWithOtp] is attempted
  String? otpErrorMessage;

  /// Error message for verify OTP.
  /// Used to specify the error message thrown when [verifyOtp] is attempted
  String? verifyOtpErrorMessage;

  /// Error message for reset password.
  /// Used to specify the error message thrown when [resetPasswordForEmail] is attempted
  String? resetPasswordErrorMessage;

  /// Error message for sign out.
  /// Used to specify the error message thrown when [signOut] is attempted
  String? signOutErrorMessage;

  /// Error message for select.
  /// Used to specify the error message thrown when [selectSingle] is attempted
  String? selectErrorMessage;

  /// Error message for insert.
  /// Used to specify the error message thrown when [insert] is attempted
  String? insertErrorMessage;

  /// Error message for update.
  /// Used to specify the error message thrown when [update] is attempted
  String? updateErrorMessage;

  /// Used to specify the type of exception thrown when [selectSingle] is attempted
  SupabaseExceptionType? selectExceptionType;

  /// Used to specify the type of exception thrown when [insert] is attempted
  SupabaseExceptionType? insertExceptionType;

  /// Used to specify the type of exception thrown when [update] is attempted
  SupabaseExceptionType? updateExceptionType;

  /// Used to specify the error code thrown when [signInWithPassword] is attempted
  SupabaseAuthErrorCode? authErrorCode;

  /// Used to specify the error code thrown during [selectSingle], [insert], and [update]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether [signInWithPassword] returns a null user
  bool shouldReturnNullUser = false;

  /// Controls whether [selectSingle] returns a null user
  bool shouldReturnNullOnSelect = false;

  /// Controls whether operations should be delayed
  bool shouldDelayOperations = false;

  /// Controlls when a delayed future is completed
  Completer? completer;

  /// Controls whether stream errors should be emitted
  bool shouldEmitStreamErrors = false;

  /// Controls whether [signInWithPassword] returns a user
  bool shouldReturnUser = false;

  /// Controls whether [signInWithPassword] throws an exception when getting the user profile
  bool shouldThrowOnGetUserProfile = false;

  /// The event that occurs when a user signs in
  supabase.AuthChangeEvent signInEvent = supabase.AuthChangeEvent.signedIn;

  /// Sets the current user
  void setCurrentUser(FakeUser? user) {
    _currentUser = user;
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      _authStateController.stream;

  @override
  supabase.User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }
    _methodCalls.add({
      'method': 'signInWithPassword',
      'email': email,
      'password': password,
    });

    if (shouldThrowOnSignIn) {
      _throwConfiguredException(
        SupabaseExceptionType.auth,
        signInErrorMessage ?? 'Sign in failed',
      );
    }

    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }

    final user = _createFakeUser(email);
    _currentUser = user;

    _authStateController.add(_createAuthState(signInEvent, user));

    return _createAuthResponse(user);
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    _methodCalls.add({
      'method': 'signUp',
      'email': email,
      'password': password,
    });

    if (shouldThrowOnSignUp) {
      _throwConfiguredException(
        SupabaseExceptionType.auth,
        signUpErrorMessage ?? 'Sign up failed',
      );
    }

    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }

    final user = _createFakeUser(email);
    _currentUser = user;

    _authStateController.add(
      _createAuthState(supabase.AuthChangeEvent.signedIn, user),
    );

    return _createAuthResponse(user);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  }) async {
    _methodCalls.add({
      'method': 'signInWithOtp',
      'email': email,
      'phone': phone,
      'shouldCreateUser': shouldCreateUser,
    });

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnOtp) {
      _throwConfiguredException(
        SupabaseExceptionType.auth,
        otpErrorMessage ?? 'OTP send failed',
      );
    }
  }

  @override
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  }) async {
    _methodCalls.add({
      'method': 'verifyOTP',
      'email': email,
      'phone': phone,
      'token': token,
      'type': type,
    });

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnVerifyOtp) {
      _throwConfiguredException(
        SupabaseExceptionType.auth,
        verifyOtpErrorMessage ?? 'OTP verification failed',
      );
    }

    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }

    final address = email ?? phone ?? 'unknown@example.com';
    final user = _createFakeUser(address);
    _currentUser = user;

    _authStateController.add(
      _createAuthState(supabase.AuthChangeEvent.signedIn, user),
    );

    return _createAuthResponse(user);
  }

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    _methodCalls.add({
      'method': 'resetPasswordForEmail',
      'email': email,
      'redirectTo': redirectTo,
    });
    if (shouldThrowOnResetPassword) {
      _throwConfiguredException(
        SupabaseExceptionType.auth,
        resetPasswordErrorMessage ?? 'Password reset failed',
      );
    }
  }

  @override
  Future<void> signOut() async {
    _methodCalls.add({'method': 'signOut'});

    if (shouldThrowOnSignOut) {
      throw ServerException(
        Trace.current(),
        Exception(signOutErrorMessage ?? 'Sign out failed'),
      );
    }

    _currentUser = null;
    _authStateController.add(
      _createAuthState(supabase.AuthChangeEvent.signedOut, null),
    );
  }

  @override
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    _methodCalls.add({
      'method': 'selectSingle',
      'table': table,
      'columns': columns,
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });
    if (shouldThrowOnSelect) {
      _throwConfiguredException(
        selectExceptionType,
        selectErrorMessage ?? 'Select failed',
      );
    }

    if (shouldReturnNullOnSelect) {
      return null;
    }

    final tableData = _tables[table] ?? [];

    for (final row in tableData) {
      if (row[filterColumn] == filterValue) {
        return Map<String, dynamic>.from(row);
      }
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    _methodCalls.add({
      'method': 'insert',
      'table': table,
      'data': Map<String, dynamic>.from(data),
    });

    if (shouldThrowOnInsert) {
      _throwConfiguredException(
        insertExceptionType,
        insertErrorMessage ?? 'Insert failed',
      );
    }

    final tableData = _tables[table] ?? [];

    final insertData = Map<String, dynamic>.from(data);
    insertData['id'] = (tableData.length + 1).toString();
    insertData['created_at'] = DateTime.now().toIso8601String();
    insertData['updated_at'] = DateTime.now().toIso8601String();

    tableData.add(insertData);
    _tables[table] = tableData;

    return Map<String, dynamic>.from(insertData);
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    _methodCalls.add({
      'method': 'update',
      'table': table,
      'data': Map<String, dynamic>.from(data),
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });

    if (shouldThrowOnUpdate) {
      _throwConfiguredException(
        updateExceptionType,
        updateErrorMessage ?? 'Update failed',
      );
    }

    final tableData = _tables[table] ?? [];

    for (int i = 0; i < tableData.length; i++) {
      if (tableData[i][filterColumn] == filterValue) {
        final updatedData = Map<String, dynamic>.from(tableData[i]);
        updatedData.addAll(data);
        updatedData['updated_at'] = DateTime.now().toIso8601String();

        tableData[i] = updatedData;
        _tables[table] = tableData;

        return Map<String, dynamic>.from(updatedData);
      }
    }

    throw ServerException(
      Trace.current(),
      Exception('Record not found for update'),
    );
  }

  @override
  Future<supabase.UserResponse> updateUser(
    supabase.UserAttributes userAttributes,
  ) async {
    _methodCalls.add({
      'method': 'updateUser',
      'userAttributes': userAttributes,
    });

    if (shouldThrowOnUpdate) {
      _throwConfiguredException(
        updateExceptionType,
        updateErrorMessage ?? 'Update failed',
      );
    }
    if (userAttributes.email != null) {
      _currentUser = _currentUser?.copyWith(email: userAttributes.email);
    }
    if (userAttributes.password != null) {
      _currentUser = _currentUser?.copyWith(
        userMetadata: {'password': userAttributes.password},
      );
    }
    return FakeUserResponse(user: _currentUser);
  }

  @override
  Future<List<Map<String, dynamic>>> selectProfessionalRoles() async {
    _methodCalls.add({
      'method': 'selectProfessionalRoles',
    });

    if (shouldThrowOnSelect) {
      _throwConfiguredException(
        selectExceptionType,
        selectErrorMessage ?? 'Select failed',
      );
    }

    if (shouldReturnNullOnSelect) {
      return [];
    }

    final tableData = _tables['professional_roles'] ?? [];
    return tableData;
  }
  
  @override
  Future<void> initialize() {
    // No need to implement this method, fake supabase wrapper does not need
    // to initialize any dependencies
    throw UnimplementedError();
  }

  FakeUser _createFakeUser(String email) {
    return FakeUser(
      id: 'fake-user-${email.hashCode}',
      email: email,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  supabase.AuthResponse _createAuthResponse(supabase.User? user) {
    supabase.Session? session;
    if (user != null) {
      session = FakeSession(user: user);
    }
    return FakeAuthResponse(user: user, session: session);
  }

  supabase.AuthState _createAuthState(
    supabase.AuthChangeEvent event,
    supabase.User? user,
  ) {
    supabase.Session? session;
    if (user != null) {
      session = FakeSession(user: user);
    }
    return FakeAuthState(event: event, session: session);
  }

  void _throwConfiguredException(
    SupabaseExceptionType? exceptionType,
    String message,
  ) {
    switch (exceptionType) {
      case SupabaseExceptionType.auth:
        throw supabase.AuthException(message, code: authErrorCode.toString());
      case SupabaseExceptionType.postgrest:
        throw supabase.PostgrestException(
          code: postgrestErrorCode.toString(),
          message: message,
        );
      case SupabaseExceptionType.socket:
        throw SocketException(message);
      case SupabaseExceptionType.timeout:
        throw TimeoutException(message);
      case SupabaseExceptionType.type:
        throw TypeError();
      default:
        throw ServerException(Trace.current(), Exception(message));
    }
  }

  /// Adds data to a specific table
  void addTableData(String table, List<Map<String, dynamic>> data) {
    _tables[table] = data;
  }

  /// Clears all data for a specific table
  void clearTableData(String table) {
    _tables[table] = [];
  }

  /// Clears all table data and the currently authenticated user
  void clearAllData() {
    _tables.clear();
    _methodCalls.clear();
    _currentUser = null;
  }

  /// Returns a list of all method calls
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);

  /// Returns the last method call
  Map<String, dynamic>? getLastMethodCall() =>
      _methodCalls.isEmpty ? null : _methodCalls.last;

  /// Returns a list of all method calls for a given method name
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Clears all method calls
  void clearMethodCalls() {
    _methodCalls.clear();
  }

  /// Closes the auth state controller
  void dispose() {
    _authStateController.close();
  }

  /// Sets an auth stream error
  void setAuthStreamError(String errorMessage, {Exception? exception}) {
    exception ??= ServerException(Trace.current(), Exception(errorMessage));
    _authStateController.addError(exception);
  }

  /// Emits an auth state error
  void emitAuthStateError(String errorMessage) {
    setAuthStreamError(errorMessage);
  }

  /// Resets all fake configurations, clears data, and auth state
  void reset() {
    shouldThrowOnSignIn = false;
    shouldThrowOnSignUp = false;
    shouldThrowOnOtp = false;
    shouldThrowOnVerifyOtp = false;
    shouldThrowOnResetPassword = false;
    shouldThrowOnSignOut = false;
    shouldThrowOnSelect = false;
    shouldThrowOnInsert = false;
    shouldThrowOnUpdate = false;

    signInErrorMessage = null;
    signUpErrorMessage = null;
    otpErrorMessage = null;
    verifyOtpErrorMessage = null;
    resetPasswordErrorMessage = null;
    signOutErrorMessage = null;
    selectErrorMessage = null;
    insertErrorMessage = null;
    updateErrorMessage = null;

    selectExceptionType = null;
    insertExceptionType = null;
    updateExceptionType = null;
    postgrestErrorCode = null;

    shouldReturnNullUser = false;
    shouldReturnNullOnSelect = false;

    shouldDelayOperations = false;
    completer = null;
    shouldEmitStreamErrors = false;
    shouldReturnUser = false;
    shouldThrowOnGetUserProfile = false;

    clearAllData();
    clearMethodCalls();
  }
}
