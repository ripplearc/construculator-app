// coverage:ignore-file
import 'dart:async';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseWrapperImpl implements SupabaseWrapper {
  late supabase.SupabaseClient _supabaseClient;
  final EnvLoader _envLoader;
  static final _logger = AppLogger().tag('SupabaseWrapperImpl');

  SupabaseWrapperImpl({required EnvLoader envLoader}) : _envLoader = envLoader;

  @override
  Future<void> initialize() async {
    final supabaseUrl = _envLoader.get('SUPABASE_URL');
    final supabaseAnonKey = _envLoader.get('SUPABASE_ANON_KEY');
    if (supabaseUrl != null && supabaseAnonKey != null) {
      await supabase.Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: _envLoader.get('DEBUG_MODE') == 'true',
      );
      _supabaseClient = supabase.Supabase.instance.client;
      return;
    }
    throw ClientException(
      Trace.current(),
      'SUPABASE_URL and SUPABASE_ANON_KEY variables are required',
    );
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  supabase.User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabaseClient.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  }) async {
    await _supabaseClient.auth.signInWithOtp(
      email: email,
      phone: phone,
      shouldCreateUser: shouldCreateUser,
    );
  }

  @override
  Future<supabase.AuthResponse> verifyOTP({
    String? email,
    String? phone,
    required String token,
    required supabase.OtpType type,
  }) async {
    return await _supabaseClient.auth.verifyOTP(
      email: email,
      phone: phone,
      token: token,
      type: type,
    );
  }

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    await _supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    return await _supabaseClient
        .from(table)
        .select(columns)
        .eq(filterColumn, filterValue);
  }

  @override
  Future<List<Map<String, dynamic>>> selectMatch({
    required String table,
    String columns = '*',
    required Map<String, dynamic> filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    var query = _supabaseClient
        .from(table)
        .select(columns)
        .match(filters.cast<String, Object>());
    if (orderBy != null) {
      return await query.order(orderBy, ascending: ascending);
    }
    return await query;
  }

  @override
  Future<List<Map<String, dynamic>>> selectWhereIn({
    required String table,
    String columns = '*',
    required String filterColumn,
    required List<dynamic> filterValues,
  }) async {
    return await _supabaseClient
        .from(table)
        .select(columns)
        .inFilter(filterColumn, filterValues);
  }

  @override
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    return await _supabaseClient
        .from(table)
        .select(columns)
        .eq(filterColumn, filterValue)
        .maybeSingle();
  }

  @override
  Future<List<Map<String, dynamic>>> selectAllProfessionalRoles() async {
    return await _supabaseClient.from('professional_roles').select('*');
  }

  @override
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    return await _supabaseClient.from(table).insert(data).select().single();
  }

  @override
  Future<void> upsert({
    required String table,
    required Map<String, dynamic> data,
    required String onConflict,
  }) async {
    await _supabaseClient
        .from(table)
        .upsert(data, onConflict: onConflict);
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    return await _supabaseClient
        .from(table)
        .update(data)
        .eq(filterColumn, filterValue)
        .select()
        .single();
  }

  @override
  Future<supabase.UserResponse> updateUser(
    supabase.UserAttributes userAttributes,
  ) async {
    return await _supabaseClient.auth.updateUser(userAttributes);
  }

  @override
  Future<void> delete({
    required String table,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    await _supabaseClient.from(table).delete().eq(filterColumn, filterValue);
  }

  @override
  Future<void> deleteMatch({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    await _supabaseClient
        .from(table)
        .delete()
        .match(filters.cast<String, Object>());
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
    return await _supabaseClient
        .from(table)
        .select(columns)
        .eq(filterColumn, filterValue)
        .order(orderColumn, ascending: ascending)
        .range(rangeFrom, rangeTo);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTable({
    required String table,
    required List<String> primaryKey,
  }) {
    return _supabaseClient.from(table).stream(primaryKey: primaryKey);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchTableFiltered({
    required String table,
    required List<String> primaryKey,
    required String filterColumn,
    required dynamic filterValue,
  }) {
    return _supabaseClient
        .from(table)
        .stream(primaryKey: primaryKey)
        .eq(filterColumn, filterValue);
  }

  @override
  Future<T> rpc<T>(String functionName, {Map<String, dynamic>? params}) async {
    return await _supabaseClient.rpc(functionName, params: params);
  }

  @override
  List<String> getProjectPermissions(String projectId) {
    final user = currentUser;
    if (user == null) return [];

    final appMetadata = user.appMetadata;
    final projectsRaw = appMetadata['projects'];

    if (projectsRaw is! Map<String, dynamic>) {
      if (projectsRaw != null) {
        _logger.warning(
          'Invalid JWT structure: projects is not a Map, got ${projectsRaw.runtimeType}',
        );
      }
      return [];
    }

    final permissionsRaw = projectsRaw[projectId];
    if (permissionsRaw is! List) {
      if (permissionsRaw != null) {
        _logger.warning(
          'Invalid JWT structure: permissions for project $projectId is not a List, got ${permissionsRaw.runtimeType}',
        );
      }
      return [];
    }

    final permissions = permissionsRaw.whereType<String>().toList();
    final droppedCount = permissionsRaw.length - permissions.length;
    if (droppedCount > 0) {
      _logger.warning(
        'Dropped $droppedCount non-String permission entries from JWT for project $projectId',
      );
    }

    return permissions;
  }

  @override
  bool hasProjectPermission(String projectId, String permissionKey) {
    return getProjectPermissions(projectId).contains(permissionKey);
  }

  @override
  Future<void> refreshSession() async {
    await _supabaseClient.auth.refreshSession();
  }

  @override
  String? getInternalUserId() {
    final user = currentUser;
    if (user == null) return null;

    final appMetadata = user.appMetadata;
    final userId = appMetadata['internal_user_id'];

    if (userId is String) return userId;

    if (userId != null) {
      _logger.warning(
        'Invalid JWT structure: internal_user_id is not a String, got ${userId.runtimeType}',
      );
    }

    return null;
  }
}
