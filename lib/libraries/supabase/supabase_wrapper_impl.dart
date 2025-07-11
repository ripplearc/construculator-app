// coverage:ignore-file
import 'dart:async';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseWrapperImpl implements SupabaseWrapper {
  late supabase.SupabaseClient _supabaseClient;
  final EnvLoader _envLoader;

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
  Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    return await _supabaseClient.from(table).insert(data).select().single();
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
}
