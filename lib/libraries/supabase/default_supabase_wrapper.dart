// coverage:ignore-file 
import 'dart:async';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class DefaultSupabaseWrapper implements SupabaseWrapper {
  final supabase.SupabaseClient supabaseClient;

  DefaultSupabaseWrapper({required this.supabaseClient});

  @override
  Stream<supabase.AuthState> get onAuthStateChange => supabaseClient.auth.onAuthStateChange;

  @override
  supabase.User? get currentUser => supabaseClient.auth.currentUser;

  @override
  bool get isAuthenticated => supabaseClient.auth.currentUser != null;

  @override
  Future<supabase.AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<supabase.AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    bool shouldCreateUser = false,
  }) async {
    await supabaseClient.auth.signInWithOtp(
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
    return await supabaseClient.auth.verifyOTP(
      email: email,
      phone: phone,
      token: token,
      type: type,
    );
  }

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    await supabaseClient.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  @override
  Future<void> signOut() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> selectSingle({
    required String table,
    String columns = '*',
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    return await supabaseClient
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
    return await supabaseClient
        .from(table)
        .insert(data)
        .select()
        .single();
  }

  @override
  Future<Map<String, dynamic>> update({
    required String table,
    required Map<String, dynamic> data,
    required String filterColumn,
    required dynamic filterValue,
  }) async {
    return await supabaseClient
        .from(table)
        .update(data)
        .eq(filterColumn, filterValue)
        .select()
        .single();
  }
} 