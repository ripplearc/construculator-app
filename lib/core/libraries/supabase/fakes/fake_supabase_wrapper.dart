import 'dart:async';
import 'dart:io';
import 'package:construculator_app_architecture/core/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Fake implementation of ISupabaseWrapper for testing
class FakeSupabaseWrapper implements ISupabaseWrapper {
  final StreamController<supabase.AuthState> _authStateController = 
      StreamController<supabase.AuthState>.broadcast();
  
  supabase.User? _currentUser;
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  
  // Parameter tracking for assertions
  final List<Map<String, dynamic>> _methodCalls = [];
  
  // Test configuration
  bool shouldThrowOnSignIn = false;
  bool shouldThrowOnSignUp = false;
  bool shouldThrowOnOtp = false;
  bool shouldThrowOnVerifyOtp = false;
  bool shouldThrowOnResetPassword = false;
  bool shouldThrowOnSignOut = false;
  bool shouldThrowOnSelect = false;
  bool shouldThrowOnInsert = false;
  bool shouldThrowOnUpdate = false;
  
  String? signInErrorMessage;
  String? signUpErrorMessage;
  String? otpErrorMessage;
  String? verifyOtpErrorMessage;
  String? resetPasswordErrorMessage;
  String? signOutErrorMessage;
  String? selectErrorMessage;
  String? insertErrorMessage;
  String? updateErrorMessage;
  
  // Exception type configuration
  String? signInExceptionType; // 'auth', 'postgrest', 'socket', 'timeout', 'type'
  String? signUpExceptionType;
  String? selectExceptionType;
  String? insertExceptionType;
  String? updateExceptionType;
  
  // PostgrestException specific configuration
  String? postgrestErrorCode;
  
  bool shouldReturnNullUser = false;
  bool shouldReturnNullOnSelect = false;
  
  // Performance and resilience testing flags
  bool shouldDelayOperations = false;
  int operationDelayMs = 100;
  bool shouldEmitStreamErrors = false;
  bool shouldReturnUser = false;
  bool shouldThrowOnGetUserProfile = false;

  @override
  Stream<supabase.AuthState> get onAuthStateChange => _authStateController.stream;

  @override
  supabase.User? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    // Add delay if configured for performance testing
    if (shouldDelayOperations) {
      await Future.delayed(Duration(milliseconds: operationDelayMs));
    }
    
    // Track method call
    _methodCalls.add({
      'method': 'signInWithPassword',
      'email': email,
      'password': password,
    });
    
    if (shouldThrowOnSignIn) {
      _throwConfiguredException(signInExceptionType, signInErrorMessage ?? 'Sign in failed');
    }
    
    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }
    
    final user = _createFakeUser(email);
    _currentUser = user;
    
    _authStateController.add(_createAuthState(supabase.AuthChangeEvent.signedIn, user));
    
    return _createAuthResponse(user);
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    // Track method call
    _methodCalls.add({
      'method': 'signUp',
      'email': email,
      'password': password,
    });
    
    if (shouldThrowOnSignUp) {
      _throwConfiguredException(signUpExceptionType, signUpErrorMessage ?? 'Sign up failed');
    }
    
    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }
    
    final user = _createFakeUser(email);
    _currentUser = user;
    
    _authStateController.add(_createAuthState(supabase.AuthChangeEvent.signedIn, user));
    
    return _createAuthResponse(user);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  }) async {
    // Track method call
    _methodCalls.add({
      'method': 'signInWithOtp',
      'email': email,
      'phone': phone,
      'shouldCreateUser': shouldCreateUser,
    });
    
    if (shouldThrowOnOtp) {
      throw Exception(otpErrorMessage ?? 'OTP send failed');
    }
    // OTP sending doesn't return anything, just simulates success
  }

  @override
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  }) async {
    // Track method call
    _methodCalls.add({
      'method': 'verifyOTP',
      'email': email,
      'phone': phone,
      'token': token,
      'type': type,
    });
    
    if (shouldThrowOnVerifyOtp) {
      throw Exception(verifyOtpErrorMessage ?? 'OTP verification failed');
    }
    
    if (shouldReturnNullUser) {
      return _createAuthResponse(null);
    }
    
    final address = email ?? phone ?? 'unknown@example.com';
    final user = _createFakeUser(address);
    _currentUser = user;
    
    _authStateController.add(_createAuthState(supabase.AuthChangeEvent.signedIn, user));
    
    return _createAuthResponse(user);
  }

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    // Track method call
    _methodCalls.add({
      'method': 'resetPasswordForEmail',
      'email': email,
      'redirectTo': redirectTo,
    });
    
    if (shouldThrowOnResetPassword) {
      throw Exception(resetPasswordErrorMessage ?? 'Password reset failed');
    }
    // Password reset doesn't return anything, just simulates success
  }

  @override
  Future<void> signOut() async {
    // Track method call
    _methodCalls.add({
      'method': 'signOut',
    });
    
    if (shouldThrowOnSignOut) {
      throw Exception(signOutErrorMessage ?? 'Sign out failed');
    }
    
    _currentUser = null;
    _authStateController.add(_createAuthState(supabase.AuthChangeEvent.signedOut, null));
  }

  @override
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    // Track method call
    _methodCalls.add({
      'method': 'selectSingle',
      'table': table,
      'columns': columns,
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });
    
    if (shouldThrowOnSelect) {
      _throwConfiguredException(selectExceptionType, selectErrorMessage ?? 'Select failed');
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
    // Track method call
    _methodCalls.add({
      'method': 'insert',
      'table': table,
      'data': Map<String, dynamic>.from(data),
    });
    
    if (shouldThrowOnInsert) {
      _throwConfiguredException(insertExceptionType, insertErrorMessage ?? 'Insert failed');
    }
    
    final tableData = _tables[table] ?? [];
    
    // Add auto-generated fields
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
    // Track method call
    _methodCalls.add({
      'method': 'update',
      'table': table,
      'data': Map<String, dynamic>.from(data),
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });
    
    if (shouldThrowOnUpdate) {
      _throwConfiguredException(updateExceptionType, updateErrorMessage ?? 'Update failed');
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
    
    throw Exception('Record not found for update');
  }

  // Helper methods for creating fake objects
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

  // Helper method to throw configured exceptions
  void _throwConfiguredException(String? exceptionType, String message) {
    switch (exceptionType) {
      case 'auth':
        throw FakeAuthException(message, code: message);
      case 'postgrest':
        throw FakePostgrestException(message, code: postgrestErrorCode);
      case 'socket':
        throw SocketException(message);
      case 'timeout':
        throw TimeoutException(message);
      case 'type':
        throw TypeError();
      default:
        throw Exception(message);
    }
  }

  // Utility methods for testing
  void addTableData(String table, List<Map<String, dynamic>> data) {
    _tables[table] = data;
  }

  void clearTableData(String table) {
    _tables[table] = [];
  }

  void clearAllData() {
    _tables.clear();
    _currentUser = null;
  }

  // Parameter tracking methods
  List<Map<String, dynamic>> getMethodCalls() => List.from(_methodCalls);
  
  Map<String, dynamic>? getLastMethodCall() => _methodCalls.isEmpty ? null : _methodCalls.last;
  
  List<Map<String, dynamic>> getMethodCallsFor(String methodName) {
    return _methodCalls.where((call) => call['method'] == methodName).toList();
  }
  
  void clearMethodCalls() {
    _methodCalls.clear();
  }

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

  void dispose() {
    _authStateController.close();
  }

  // Method to simulate auth stream errors for testing
  void simulateAuthStreamError(String errorMessage) {
    _authStateController.addError(Exception(errorMessage));
  }
  
  // Alias for test compatibility
  void emitAuthStateError(String errorMessage) {
    simulateAuthStreamError(errorMessage);
  }
}

// Fake exception classes that mimic Supabase exceptions
class FakeAuthException implements supabase.AuthException {
  @override
  final String message;
  
  @override
  final String? statusCode;

  @override
  final String? code;

  FakeAuthException(this.message, {this.statusCode, this.code});

  @override
  String toString() => message;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePostgrestException implements supabase.PostgrestException {
  @override
  final String message;
  
  @override
  final String? code;
  
  @override
  final String? details;
  
  @override
  final String? hint;

  FakePostgrestException(this.message, {this.code, this.details, this.hint});

  @override
  String toString() => message;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSession implements supabase.Session {
  @override
  final supabase.User user;
  
  @override
  final String accessToken;
  
  @override
  final String refreshToken;

  FakeSession({
    required this.user,
    this.accessToken = 'fake-access-token',
    this.refreshToken = 'fake-refresh-token',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Fake implementations of Supabase classes
class FakeUser implements supabase.User {
  @override
  final String id;
  
  @override
  final String? email;
  
  @override
  final String createdAt;
  
  @override
  final Map<String, dynamic> appMetadata;
  
  @override
  final Map<String, dynamic>? userMetadata;

  FakeUser({
    required this.id,
    this.email,
    required this.createdAt,
    this.appMetadata = const {},
    this.userMetadata,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthResponse implements supabase.AuthResponse {
  @override
  final supabase.User? user;
  
  @override
  final supabase.Session? session;

  FakeAuthResponse({this.user, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthState implements supabase.AuthState {
  @override
  final supabase.AuthChangeEvent event;
  
  @override
  final supabase.Session? session;

  FakeAuthState({required this.event, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
} 