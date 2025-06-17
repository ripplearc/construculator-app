import 'dart:async';
import 'dart:io';
import 'package:construculator/libraries/errors/exceptions.dart';
<<<<<<< HEAD
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> c96cea6 (Add test supabase module)
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_state.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
<<<<<<< HEAD
<<<<<<< HEAD
import 'package:stack_trace/stack_trace.dart';
=======
import 'package:construculator/libraries/supabase/testing/fake_supabase_classes.dart';
>>>>>>> d7a8e6a (Separate supabase fake classes from main wrapper class)
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

<<<<<<< HEAD
<<<<<<< HEAD
=======
=======
import 'package:stack_trace/stack_trace.dart';
>>>>>>> dba60ba (Refactor: use app defined exceptions)
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

enum FakeExceptionType{
  auth,
  postgrest,
  socket,
  timeout,
  type,
  unknown
}
>>>>>>> c96cea6 (Add test supabase module)
/// Fake implementation of SupabaseWrapper for testing
class FakeSupabaseWrapper implements SupabaseWrapper {

  /// Used to notify listeners of changes in the authentication state through [onAuthStateChange]
<<<<<<< HEAD
=======
/// Fake implementation of ISupabaseWrapper for testing
=======
/// Fake implementation of SupabaseWrapper for testing
>>>>>>> 0836451 (Fix restack errors)
class FakeSupabaseWrapper implements SupabaseWrapper {
>>>>>>> 5b674ca (Refactor supabase library to be more consistent with conventions)
=======
>>>>>>> 704ddee (Update comments)
  final StreamController<supabase.AuthState> _authStateController = 
      StreamController<supabase.AuthState>.broadcast();
  
  /// Tracks the currently authenticated user
  supabase.User? _currentUser;

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
  
<<<<<<< HEAD
<<<<<<< HEAD
  /// Used to specify the type of exception thrown when [signInWithPassword] is attempted
<<<<<<< HEAD
  SupabaseExceptionType? signInExceptionType;

  /// Used to specify the type of exception thrown when [signUp] is attempted
  SupabaseExceptionType? signUpExceptionType;

  /// Used to specify the type of exception thrown when [selectSingle] is attempted
  SupabaseExceptionType? selectExceptionType;

  /// Used to specify the type of exception thrown when [insert] is attempted
  SupabaseExceptionType? insertExceptionType;

  /// Used to specify the type of exception thrown when [update] is attempted
  SupabaseExceptionType? updateExceptionType;

  /// Used to specify the error code thrown when [signInWithPassword] is attempted
  SupabaseAuthErrorCode? signInErrorCode;
=======
  // Exception type configuration
=======
  /// Used to specify the type of exception thrown when [signInWithPassword] is attempted
>>>>>>> 0836451 (Fix restack errors)
  String? signInExceptionType; // 'auth', 'postgrest', 'socket', 'timeout', 'type'
=======
  FakeExceptionType? signInExceptionType;
>>>>>>> c96cea6 (Add test supabase module)

  /// Used to specify the type of exception thrown when [signUp] is attempted
  FakeExceptionType? signUpExceptionType;

  /// Used to specify the type of exception thrown when [selectSingle] is attempted
  FakeExceptionType? selectExceptionType;

  /// Used to specify the type of exception thrown when [insert] is attempted
  FakeExceptionType? insertExceptionType;

  /// Used to specify the type of exception thrown when [update] is attempted
  FakeExceptionType? updateExceptionType;

  /// Used to specify the error code thrown when [signInWithPassword] is attempted
  String? signInErrorCode;
>>>>>>> 1f92bb4 (Refactor)
  
  /// Used to specify the error code thrown when [selectSingle] is attempted
  String? selectErrorCode;

  /// Used to specify the error code thrown when [insert] is attempted
  String? insertErrorCode;

  /// Used to specify the error code thrown during [selectSingle], [insert], and [update]
<<<<<<< HEAD
  PostgresErrorCode? postgrestErrorCode;
=======
  String? postgrestErrorCode;
>>>>>>> 0836451 (Fix restack errors)

  /// Used to specify the error code thrown when [update] is attempted
  String? updateErrorCode;
  
  /// Controls whether [signInWithPassword] returns a null user
  bool shouldReturnNullUser = false;

  /// Controls whether [selectSingle] returns a null user
  bool shouldReturnNullOnSelect = false;
  
  /// Controls whether operations should be delayed
  bool shouldDelayOperations = false;

  /// The delay duration in milliseconds for operations
  int operationDelayMs = 100;

  /// Controls whether stream errors should be emitted
  bool shouldEmitStreamErrors = false;

  /// Controls whether [signInWithPassword] returns a user
  bool shouldReturnUser = false;

  /// Controls whether [signInWithPassword] throws an exception when getting the user profile
  bool shouldThrowOnGetUserProfile = false;
  supabase.AuthChangeEvent signInEvent = supabase.AuthChangeEvent.signedIn;

  void setCurrentUser(supabase.User? user) {
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
      await Future.delayed(Duration(milliseconds: operationDelayMs));
    }
    _methodCalls.add({
      'method': 'signInWithPassword',
      'email': email,
      'password': password,
    });

    if (shouldThrowOnSignIn) {
      _throwConfiguredException(
        signInExceptionType,
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
        signUpExceptionType,
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

    if (shouldThrowOnOtp) {
      throw ServerException(Trace.current(), Exception(otpErrorMessage ?? 'OTP send failed'));
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

    if (shouldThrowOnVerifyOtp) {
      throw ServerException(Trace.current(), Exception(verifyOtpErrorMessage ?? 'OTP verification failed'));
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
      throw ServerException(Trace.current(), Exception(resetPasswordErrorMessage ?? 'Password reset failed'));
    }
  }

  @override
  Future<void> signOut() async {
    _methodCalls.add({
      'method': 'signOut',
    });
    
    if (shouldThrowOnSignOut) {
      throw ServerException(Trace.current(), Exception(signOutErrorMessage ?? 'Sign out failed'));
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
<<<<<<< HEAD

=======
    
>>>>>>> dba60ba (Refactor: use app defined exceptions)
    throw ServerException(Trace.current(), Exception('Record not found for update'));
  }

  supabase.User _createFakeUser(String email) {
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

  supabase.AuthState _createAuthState(supabase.AuthChangeEvent event, supabase.User? user) {
    supabase.Session? session;
    if (user != null) {
      session = FakeSession(user: user);
    }
    return FakeAuthState(event: event, session: session);
  }

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  void _throwConfiguredException(SupabaseExceptionType? exceptionType, String message) {
=======
  void _throwConfiguredException(String? exceptionType, String message) {
>>>>>>> 0836451 (Fix restack errors)
    switch (exceptionType) {
<<<<<<< HEAD
      case SupabaseExceptionType.auth:
        throw supabase.AuthException(message, code: signInErrorCode.toString());
      case SupabaseExceptionType.postgrest:
        throw supabase.PostgrestException(code: postgrestErrorCode.toString(), message: message);
      case SupabaseExceptionType.socket:
=======
      case 'auth':
=======
=======
  /// Throws an exception based on the configured exception type and message
>>>>>>> 704ddee (Update comments)
=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)
  void _throwConfiguredException(FakeExceptionType? exceptionType, String message) {
    switch (exceptionType) {
      case FakeExceptionType.auth:
>>>>>>> c96cea6 (Add test supabase module)
        throw supabase.AuthException(message, code: signInErrorCode);
      case FakeExceptionType.postgrest:
        throw supabase.PostgrestException(code: postgrestErrorCode, message: message);
<<<<<<< HEAD
      case 'socket':
>>>>>>> 1f92bb4 (Refactor)
        throw SocketException(message);
      case SupabaseExceptionType.timeout:
        throw TimeoutException(message);
      case SupabaseExceptionType.type:
=======
      case FakeExceptionType.socket:
        throw SocketException(message);
      case FakeExceptionType.timeout:
        throw TimeoutException(message);
      case FakeExceptionType.type:
>>>>>>> c96cea6 (Add test supabase module)
        throw TypeError();
      default:
        throw ServerException(Trace.current(), Exception(message));
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
  /// Adds data to a specific table
=======
>>>>>>> 0836451 (Fix restack errors)
=======
  /// Adds data to a specific table
>>>>>>> 704ddee (Update comments)
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
  Map<String, dynamic>? getLastMethodCall() => _methodCalls.isEmpty ? null : _methodCalls.last;
  
  /// Returns a list of all method calls for a given method name
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }

  /// Clears all method calls
  void clearMethodCalls() {
    _methodCalls.clear();
  }
<<<<<<< HEAD
=======

<<<<<<< HEAD
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
    
    signInExceptionType = null;
    signUpExceptionType = null;
    selectExceptionType = null;
    insertExceptionType = null;
    updateExceptionType = null;
    postgrestErrorCode = null;
    
    shouldReturnNullUser = false;
    shouldReturnNullOnSelect = false;
    
    shouldDelayOperations = false;
    operationDelayMs = 100;
    shouldEmitStreamErrors = false;
    shouldReturnUser = false;
    shouldThrowOnGetUserProfile = false;
    
    clearAllData();
    clearMethodCalls();
  }

>>>>>>> 704ddee (Update comments)
=======
>>>>>>> dba60ba (Refactor: use app defined exceptions)
  /// Closes the auth state controller
  void dispose() {
    _authStateController.close();
  }

<<<<<<< HEAD
<<<<<<< HEAD
  /// Sets an auth stream error
  void setAuthStreamError(String errorMessage,{Exception? exception}) {
    var ex = Exception(errorMessage);
    if(exception != null){
      ex = exception;
    }
    _authStateController.addError(ServerException(Trace.current(), ex));
=======
  /// Simulates an auth stream error
<<<<<<< HEAD
  void simulateAuthStreamError(String errorMessage) {
    _authStateController.addError(Exception(errorMessage));
>>>>>>> 0836451 (Fix restack errors)
=======
  void simulateAuthStreamError(String errorMessage,{Exception? exception}) {
=======
  /// Sets an auth stream error
  void setAuthStreamError(String errorMessage,{Exception? exception}) {
>>>>>>> dba60ba (Refactor: use app defined exceptions)
    var ex = Exception(errorMessage);
    if(exception != null){
      ex = exception;
    }
<<<<<<< HEAD
    _authStateController.addError(ex);
>>>>>>> 46a12a3 (Accept an optional exception)
=======
    _authStateController.addError(ServerException(Trace.current(), ex));
>>>>>>> dba60ba (Refactor: use app defined exceptions)
  }
  
  /// Emits an auth state error
  void emitAuthStateError(String errorMessage) {
    setAuthStreamError(errorMessage);
  }
  
  @override
  Future<void> initialize() {
    // No need to implement this method, fake supabase wrapper does not need 
    // to initialize any dependencies
    throw UnimplementedError();
  }
<<<<<<< HEAD
<<<<<<< HEAD
}
=======
}
>>>>>>> d7a8e6a (Separate supabase fake classes from main wrapper class)
=======
}
>>>>>>> 0836451 (Fix restack errors)
