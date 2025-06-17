<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
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
    }
    throw ClientException(Trace.current(), 'SUPABASE_URL and SUPABASE_ANON_KEY variables are required');
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      _supabaseClient.auth.onAuthStateChange;

  @override
  supabase.User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;
=======
// coverage:ignore-file 
=======
// coverage:ignore-file
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
import 'dart:async';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
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
    }
    throw Exception('SUPABASE_URL and SUPABASE_ANON_KEY variables are required');
  }

  @override
  Stream<supabase.AuthState> get onAuthStateChange =>
      _supabaseClient.auth.onAuthStateChange;

  @override
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
  bool get isAuthenticated => _client.auth.currentUser != null;
>>>>>>> 5777a70 (Fix restack errors)
=======
  bool get isAuthenticated => supabaseClient.auth.currentUser != null;
>>>>>>> 3915f4d (Fix restack errors)
=======
  supabase.User? get currentUser => _supabaseClient.auth.currentUser;

  @override
  bool get isAuthenticated => _supabaseClient.auth.currentUser != null;
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient.auth.signInWithPassword(
=======
    return await _client.auth.signInWithPassword(
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await supabaseClient.auth.signInWithPassword(
>>>>>>> 3915f4d (Fix restack errors)
=======
    return await _supabaseClient.auth.signInWithPassword(
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
      email: email,
      password: password,
    );
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient.auth.signUp(email: email, password: password);
=======
    return await _client.auth.signUp(
=======
    return await supabaseClient.auth.signUp(
>>>>>>> 3915f4d (Fix restack errors)
      email: email,
      password: password,
    );
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await _supabaseClient.auth.signUp(email: email, password: password);
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  }) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    await _supabaseClient.auth.signInWithOtp(
=======
    await _client.auth.signInWithOtp(
>>>>>>> 5777a70 (Fix restack errors)
=======
    await supabaseClient.auth.signInWithOtp(
>>>>>>> 3915f4d (Fix restack errors)
=======
    await _supabaseClient.auth.signInWithOtp(
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
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
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient.auth.verifyOTP(
=======
    return await _client.auth.verifyOTP(
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await supabaseClient.auth.verifyOTP(
>>>>>>> 3915f4d (Fix restack errors)
=======
    return await _supabaseClient.auth.verifyOTP(
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
      email: email,
      phone: phone,
      token: token,
      type: type,
    );
  }

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
    await _supabaseClient.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
=======
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
>>>>>>> 5777a70 (Fix restack errors)
=======
    await supabaseClient.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
>>>>>>> 3915f4d (Fix restack errors)
=======
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
  }

  @override
  Future<void> signOut() async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    await _supabaseClient.auth.signOut();
=======
    await _client.auth.signOut();
>>>>>>> 5777a70 (Fix restack errors)
=======
    await supabaseClient.auth.signOut();
>>>>>>> 3915f4d (Fix restack errors)
=======
    await _supabaseClient.auth.signOut();
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
  }

  @override
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient
=======
    return await _client
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await supabaseClient
>>>>>>> 3915f4d (Fix restack errors)
=======
    return await _supabaseClient
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
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
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient.from(table).insert(data).select().single();
=======
    return await _client
=======
    return await supabaseClient
>>>>>>> 3915f4d (Fix restack errors)
        .from(table)
        .insert(data)
        .select()
        .single();
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await _supabaseClient.from(table).insert(data).select().single();
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
<<<<<<< HEAD
    return await _supabaseClient
=======
    return await _client
>>>>>>> 5777a70 (Fix restack errors)
=======
    return await supabaseClient
>>>>>>> 3915f4d (Fix restack errors)
=======
    return await _supabaseClient
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
        .from(table)
        .update(data)
        .eq(filterColumn, filterValue)
        .select()
        .single();
  }
<<<<<<< HEAD:lib/libraries/supabase/default_supabase_wrapper.dart
<<<<<<< HEAD
}
=======
} 
>>>>>>> 5777a70 (Fix restack errors)
=======
}
>>>>>>> 0836451 (Fix restack errors):lib/libraries/supabase/supabase_wrapper_impl.dart
