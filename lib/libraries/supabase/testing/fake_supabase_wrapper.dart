import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/data/supabase_types.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_response.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_auth_state.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_session.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_user.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Fake implementation of SupabaseWrapper for testing
class FakeSupabaseWrapper implements SupabaseWrapper {
  /// Used to notify listeners of changes in the authentication state through [onAuthStateChange]
  final StreamController<supabase.AuthState> _authStateController =
      StreamController<supabase.AuthState>.broadcast();

  /// Tracks the currently authenticated user
  FakeUser? _currentUser;

  /// Tracks table data for assertions during [select], [selectSingle], [insert], and [update]
  final Map<String, List<Map<String, dynamic>>> _tables = {};

  /// Tracks live table stream controllers for real-time table updates.
  final Map<String, StreamController<List<Map<String, dynamic>>>>
  _tableDataControllers = {};

  /// Tracks method calls for assertions
  final List<Map<String, dynamic>> _methodCalls = [];

  /// Tracks RPC responses for different function names
  final Map<String, dynamic> _rpcResponses = {};

  /// Tracks permissions by project ID for testing
  final Map<String, List<String>> _projectPermissions = {};

  /// Tracks internal user ID for testing
  String? _internalUserId;

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

  /// Controls whether [select] throws an exception
  bool shouldThrowOnSelectMultiple = false;

  /// Controls whether [selectSingle] throws an exception
  bool shouldThrowOnSelect = false;

  /// Controls whether [insert] throws an exception
  bool shouldThrowOnInsert = false;

  /// Controls whether [update] throws an exception
  bool shouldThrowOnUpdate = false;

  /// Controls whether [delete] throws an exception
  bool shouldThrowOnDelete = false;

  /// Controls whether [deleteMatch] throws an exception
  bool shouldThrowOnDeleteMatch = false;

  /// Controls whether [selectMatch] throws an exception
  bool shouldThrowOnSelectMatch = false;

  /// Controls whether [upsert] throws an exception
  bool shouldThrowOnUpsert = false;

  /// Controls whether [selectPaginated] throws an exception
  bool shouldThrowOnSelectPaginated = false;

  /// Controls whether [rpc] throws an exception
  bool shouldThrowOnRpc = false;

  /// Controls whether [refreshSession] throws an exception
  bool shouldThrowOnRefreshSession = false;

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
  /// Used to specify the error message thrown when [select] is attempted
  String? selectMultipleErrorMessage;

  /// Error message for select.
  /// Used to specify the error message thrown when [selectSingle] is attempted
  String? selectErrorMessage;

  /// Error message for insert.
  /// Used to specify the error message thrown when [insert] is attempted
  String? insertErrorMessage;

  /// Error message for update.
  /// Used to specify the error message thrown when [update] is attempted
  String? updateErrorMessage;

  /// Error message for delete.
  /// Used to specify the error message thrown when [delete] is attempted
  String? deleteErrorMessage;

  /// Error message for deleteMatch.
  /// Used to specify the error message thrown when [deleteMatch] is attempted
  String? deleteMatchErrorMessage;

  /// Error message for selectMatch.
  /// Used to specify the error message thrown when [selectMatch] is attempted
  String? selectMatchErrorMessage;

  /// Error message for upsert.
  /// Used to specify the error message thrown when [upsert] is attempted
  String? upsertErrorMessage;

  /// Error message for selectPaginated.
  /// Used to specify the error message thrown when [selectPaginated] is attempted
  String? selectPaginatedErrorMessage;

  /// Error message for RPC.
  /// Used to specify the error message thrown when [rpc] is attempted
  String? rpcErrorMessage;

  /// Error message for refresh session.
  /// Used to specify the error message thrown when [refreshSession] is attempted
  String? refreshSessionErrorMessage;

  /// Error message for select.
  /// Used to specify the error message thrown when [select] is attempted
  SupabaseExceptionType? selectMultipleExceptionType;

  /// Used to specify the type of exception thrown when [selectSingle] is attempted
  SupabaseExceptionType? selectExceptionType;

  /// Used to specify the type of exception thrown when [insert] is attempted
  SupabaseExceptionType? insertExceptionType;

  /// Used to specify the type of exception thrown when [update] is attempted
  SupabaseExceptionType? updateExceptionType;

  /// Used to specify the type of exception thrown when [delete] is attempted
  SupabaseExceptionType? deleteExceptionType;

  /// Used to specify the type of exception thrown when [deleteMatch] is attempted
  SupabaseExceptionType? deleteMatchExceptionType;

  /// Used to specify the type of exception thrown when [selectMatch] is attempted
  SupabaseExceptionType? selectMatchExceptionType;

  /// Used to specify the type of exception thrown when [upsert] is attempted
  SupabaseExceptionType? upsertExceptionType;

  /// Used to specify the type of exception thrown when [selectPaginated] is attempted
  SupabaseExceptionType? selectPaginatedExceptionType;

  /// Used to specify the type of exception thrown when [rpc] is attempted
  SupabaseExceptionType? rpcExceptionType;

  /// Used to specify the type of exception thrown when [refreshSession] is attempted
  SupabaseExceptionType? refreshSessionExceptionType;

  /// Used to specify the error code thrown when [signInWithPassword] is attempted
  SupabaseAuthErrorCode? authErrorCode;

  /// Used to specify the error code thrown during [select], [selectSingle], [insert], and [update]
  PostgresErrorCode? postgrestErrorCode;

  /// Controls whether [signInWithPassword] returns a null user
  bool shouldReturnNullUser = false;

  /// Controls whether [select] returns a null user
  bool shouldReturnNullOnSelectMultiple = false;

  /// Controls whether [selectMatch] returns an empty list
  bool shouldReturnEmptyOnSelectMatch = false;

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

  /// Auto-incrementing counter for generating unique record IDs
  int _nextId = 1;

  final Clock _clock;

  /// Constructor for fake supabase wrapper
  FakeSupabaseWrapper({required Clock clock}) : _clock = clock;

  /// Sets the current user
  void setCurrentUser(FakeUser? user) {
    _currentUser = user;

    if (user != null) {
      _authStateController.add(_createAuthState(signInEvent, user));
    } else {
      _authStateController.add(
        _createAuthState(supabase.AuthChangeEvent.signedOut, null),
      );
    }
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
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }
    _methodCalls.add({
      'method': 'select',
      'table': table,
      'columns': columns,
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });

    if (shouldThrowOnSelectMultiple) {
      _throwConfiguredException(
        selectMultipleExceptionType,
        selectMultipleErrorMessage ?? 'Select failed',
      );
    }

    if (shouldReturnNullOnSelectMultiple) {
      return [];
    }

    final tableData = _tables[table] ?? [];
    final filteredData = tableData
        .where((row) => row[filterColumn] == filterValue)
        .toList();
    return filteredData;
  }

  @override
  Future<List<Map<String, dynamic>>> selectMatch({
    required String table,
    String columns = '*',
    required Map<String, dynamic> filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    _methodCalls.add({
      'method': 'selectMatch',
      'table': table,
      'columns': columns,
      'filters': Map<String, dynamic>.from(filters),
      if (orderBy != null) 'orderBy': orderBy,
      'ascending': ascending,
    });

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnSelectMatch) {
      _throwConfiguredException(
        selectMatchExceptionType,
        selectMatchErrorMessage ?? 'Select match failed',
      );
    }

    if (shouldReturnEmptyOnSelectMatch) {
      return [];
    }

    final tableData = _tables[table] ?? [];
    final results = tableData
        .where(
          (row) =>
              filters.entries.every((entry) => row[entry.key] == entry.value),
        )
        .toList();

    if (orderBy != null) {
      results.sort((a, b) {
        final aVal = a[orderBy];
        final bVal = b[orderBy];
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return ascending ? -1 : 1;
        if (bVal == null) return ascending ? 1 : -1;
        final cmp = (aVal is Comparable && bVal is Comparable)
            ? (aVal).compareTo(bVal)
            : aVal.toString().compareTo(bVal.toString());
        return ascending ? cmp : -cmp;
      });
    }

    return results;
  }

  @override
  Future<List<Map<String, dynamic>>> selectWhereIn({
    required String table,
    String columns = '*',
    required String filterColumn,
    required List<dynamic> filterValues,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }
    _methodCalls.add({
      'method': 'selectWhereIn',
      'table': table,
      'columns': columns,
      'filterColumn': filterColumn,
      'filterValues': List<dynamic>.from(filterValues),
    });

    if (shouldThrowOnSelectMultiple) {
      _throwConfiguredException(
        selectMultipleExceptionType,
        selectMultipleErrorMessage ?? 'Select failed',
      );
    }

    if (shouldReturnNullOnSelectMultiple) {
      return [];
    }

    final tableData = _tables[table] ?? [];
    final filteredData = tableData
        .where((row) => filterValues.contains(row[filterColumn]))
        .toList();
    return filteredData;
  }

  @override
  Future<List<Map<String, dynamic>>> selectPaginated({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
    required String orderColumn,
    bool ascending = false,
    required int rangeFrom,
    required int rangeTo,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }
    _methodCalls.add({
      'method': 'selectPaginated',
      'table': table,
      'columns': columns,
      'filterColumn': filterColumn,
      'filterValue': filterValue,
      'orderColumn': orderColumn,
      'ascending': ascending,
      'rangeFrom': rangeFrom,
      'rangeTo': rangeTo,
    });

    if (shouldThrowOnSelectPaginated) {
      _throwConfiguredException(
        selectPaginatedExceptionType,
        selectPaginatedErrorMessage ?? 'Select paginated failed',
      );
    }

    final tableData = _tables[table] ?? [];
    var filteredData = tableData
        .where((row) => row[filterColumn] == filterValue)
        .toList();

    filteredData.sort((a, b) {
      final aVal = a[orderColumn];
      final bVal = b[orderColumn];
      if (aVal is Comparable && bVal is Comparable) {
        return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
      }
      return 0;
    });

    final from = rangeFrom.clamp(0, filteredData.length);
    final to = (rangeTo + 1).clamp(0, filteredData.length);
    return filteredData.sublist(from, to);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTable({
    required String table,
    required List<String> primaryKey,
  }) async* {
    _methodCalls.add({
      'method': 'watchTable',
      'table': table,
      'primaryKey': List<String>.from(primaryKey),
    });

    final controller = _getOrCreateTableController(table);
    yield _cloneRows(_tables[table] ?? const []);
    yield* controller.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTableFiltered({
    required String table,
    required List<String> primaryKey,
    required String filterColumn,
    required dynamic filterValue,
  }) async* {
    _methodCalls.add({
      'method': 'watchTableFiltered',
      'table': table,
      'primaryKey': List<String>.from(primaryKey),
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });

    final controller = _getOrCreateTableController(table);
    List<Map<String, dynamic>> applyFilter(List<Map<String, dynamic>> rows) {
      return rows
          .where((row) => row[filterColumn] == filterValue)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }

    yield applyFilter(_tables[table] ?? const []);
    yield* controller.stream.map(applyFilter);
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

    if (shouldDelayOperations) {
      await completer?.future;
    }

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

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnInsert) {
      _throwConfiguredException(
        insertExceptionType,
        insertErrorMessage ?? 'Insert failed',
      );
    }

    final tableData = _tables[table] ?? [];

    final insertData = Map<String, dynamic>.from(data);
    insertData['id'] = (_nextId++).toString();
    insertData['created_at'] = _clock.now().toIso8601String();
    insertData['updated_at'] = _clock.now().toIso8601String();

    tableData.add(insertData);
    _tables[table] = tableData;
    _emitTableData(table);

    return Map<String, dynamic>.from(insertData);
  }

  @override
  Future<void> upsert({
    required String table,
    required Map<String, dynamic> data,
    required String onConflict,
  }) async {
    _methodCalls.add({
      'method': 'upsert',
      'table': table,
      'data': Map<String, dynamic>.from(data),
      'onConflict': onConflict,
    });

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnUpsert) {
      _throwConfiguredException(
        upsertExceptionType,
        upsertErrorMessage ?? 'Upsert failed',
      );
    }

    final conflictColumns = onConflict
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty);

    final tableData = _tables[table] ?? [];
    final existingIndex = tableData.indexWhere((row) {
      return conflictColumns.every((col) => row[col] == data[col]);
    });

    final upsertData = Map<String, dynamic>.from(data);
    upsertData['updated_at'] = _clock.now().toIso8601String();

    if (existingIndex >= 0) {
      upsertData['created_at'] = tableData[existingIndex]['created_at'];
      tableData[existingIndex] = upsertData;
    } else {
      upsertData['id'] = (_nextId++).toString();
      upsertData['created_at'] = _clock.now().toIso8601String();
      tableData.add(upsertData);
    }
    _tables[table] = tableData;
    _emitTableData(table);
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

    if (shouldDelayOperations) {
      await completer?.future;
    }

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
        updatedData['updated_at'] = _clock.now().toIso8601String();

        tableData[i] = updatedData;
        _tables[table] = tableData;
        _emitTableData(table);

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
  Future<void> delete({
    required String table,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'delete',
      'table': table,
      'filterColumn': filterColumn,
      'filterValue': filterValue,
    });

    if (shouldThrowOnDelete) {
      _throwConfiguredException(
        deleteExceptionType,
        deleteErrorMessage ?? 'Delete failed',
      );
    }

    final tableData = _tables[table] ?? [];

    final filteredData = tableData
        .where((row) => row[filterColumn] != filterValue)
        .toList();
    _tables[table] = filteredData;
    _emitTableData(table);
  }

  @override
  Future<void> deleteMatch({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    _methodCalls.add({
      'method': 'deleteMatch',
      'table': table,
      'filters': Map<String, dynamic>.from(filters),
    });

    if (shouldDelayOperations) {
      await completer?.future;
    }

    if (shouldThrowOnDeleteMatch) {
      _throwConfiguredException(
        deleteMatchExceptionType,
        deleteMatchErrorMessage ?? 'Delete match failed',
      );
    }

    final tableData = _tables[table] ?? [];
    _tables[table] = tableData
        .where(
          (row) =>
              !filters.entries.every((entry) => row[entry.key] == entry.value),
        )
        .toList();
    _emitTableData(table);
  }

  @override
  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params}) async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({
      'method': 'rpc',
      'functionName': functionName,
      'params': params,
    });

    if (shouldThrowOnRpc) {
      _throwConfiguredException(
        rpcExceptionType,
        rpcErrorMessage ?? 'RPC failed',
      );
    }

    if (_rpcResponses.containsKey(functionName)) {
      return _rpcResponses[functionName] as T;
    }

    throw ServerException(
      Trace.current(),
      Exception('No RPC response configured for function: $functionName'),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> selectAllProfessionalRoles() async {
    _methodCalls.add({'method': 'selectAllProfessionalRoles'});

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
  List<String> getProjectPermissions(String projectId) {
    _methodCalls.add({
      'method': 'getProjectPermissions',
      'projectId': projectId,
    });
    return List<String>.from(_projectPermissions[projectId] ?? []);
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    _methodCalls.add({
      'method': 'hasProjectPermission',
      'projectId': projectId,
      'permissionKey': permissionKey,
    });
    return _projectPermissions[projectId]?.contains(permissionKey) ?? false;
  }

  @override
  Future<void> refreshSession() async {
    if (shouldDelayOperations) {
      await completer?.future;
    }

    _methodCalls.add({'method': 'refreshSession'});

    if (shouldThrowOnRefreshSession) {
      _throwConfiguredException(
        refreshSessionExceptionType,
        refreshSessionErrorMessage ?? 'Refresh session failed',
      );
    }
  }

  @override
  String? getInternalUserId() {
    _methodCalls.add({'method': 'getInternalUserId'});
    return _internalUserId;
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
      createdAt: _clock.now().toIso8601String(),
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

  StreamController<List<Map<String, dynamic>>> _getOrCreateTableController(
    String table,
  ) {
    return _tableDataControllers.putIfAbsent(
      table,
      () => StreamController<List<Map<String, dynamic>>>.broadcast(
        onCancel: () => _tableDataControllers.remove(table),
      ),
    );
  }

  void _emitTableData(String table) {
    final controller = _tableDataControllers[table];
    if (controller == null || controller.isClosed) {
      return;
    }
    if (shouldEmitStreamErrors) {
      controller.addError(
        ServerException(
          Trace.current(),
          Exception('Stream error for table: $table'),
        ),
      );
      return;
    }
    controller.add(_cloneRows(_tables[table] ?? const []));
  }

  List<Map<String, dynamic>> _cloneRows(List<Map<String, dynamic>> rows) {
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  /// Adds data to a specific table
  void addTableData(String table, List<Map<String, dynamic>> data) {
    _tables[table] = data;
    _emitTableData(table);
  }

  /// Clears all data for a specific table
  void clearTableData(String table) {
    _tables[table] = [];
    _emitTableData(table);
  }

  /// Clears all table data and the currently authenticated user
  void clearAllData() {
    final affectedTables = _tables.keys.toList();
    _tables.clear();
    _methodCalls.clear();
    _currentUser = null;
    for (final table in affectedTables) {
      _emitTableData(table);
    }
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

  /// Sets the response for a specific RPC function
  void setRpcResponse(String functionName, dynamic response) {
    _rpcResponses[functionName] = response;
  }

  /// Clears all RPC responses
  void clearRpcResponses() {
    _rpcResponses.clear();
  }

  /// Sets permissions for a specific project (for testing)
  void setProjectPermissions(String projectId, List<String> permissions) {
    _projectPermissions[projectId] = List<String>.from(permissions);
  }

  /// Clears permissions for a specific project (for testing)
  void clearProjectPermissions(String projectId) {
    _projectPermissions.remove(projectId);
  }

  /// Sets the internal user ID (for testing)
  void setInternalUserId(String? userId) {
    _internalUserId = userId;
  }

  /// Closes the auth state controller
  void dispose() {
    _authStateController.close();
    for (final controller in _tableDataControllers.values) {
      controller.close();
    }
    _tableDataControllers.clear();
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
    shouldThrowOnSelectMultiple = false;
    shouldThrowOnSelectMatch = false;
    shouldThrowOnSelectPaginated = false;
    shouldThrowOnDelete = false;
    shouldThrowOnDeleteMatch = false;
    shouldThrowOnUpsert = false;
    shouldThrowOnRpc = false;
    shouldThrowOnRefreshSession = false;

    signInErrorMessage = null;
    signUpErrorMessage = null;
    otpErrorMessage = null;
    verifyOtpErrorMessage = null;
    resetPasswordErrorMessage = null;
    signOutErrorMessage = null;
    selectErrorMessage = null;
    selectMatchErrorMessage = null;
    selectPaginatedErrorMessage = null;
    insertErrorMessage = null;
    updateErrorMessage = null;
    deleteErrorMessage = null;
    deleteMatchErrorMessage = null;
    upsertErrorMessage = null;
    rpcErrorMessage = null;
    refreshSessionErrorMessage = null;

    selectExceptionType = null;
    selectPaginatedExceptionType = null;
    selectMultipleExceptionType = null;
    selectMatchExceptionType = null;
    insertExceptionType = null;
    updateExceptionType = null;
    deleteExceptionType = null;
    deleteMatchExceptionType = null;
    upsertExceptionType = null;
    rpcExceptionType = null;
    refreshSessionExceptionType = null;
    postgrestErrorCode = null;

    shouldReturnNullUser = false;
    shouldReturnNullOnSelect = false;
    shouldReturnEmptyOnSelectMatch = false;

    shouldDelayOperations = false;
    completer = null;
    shouldEmitStreamErrors = false;
    shouldReturnUser = false;
    shouldThrowOnGetUserProfile = false;
    _nextId = 1;

    clearAllData();
    clearMethodCalls();
    clearRpcResponses();
  }
}
