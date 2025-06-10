// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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

class FakeSupabaseClient extends supabase.SupabaseClient{
  FakeSupabaseClient(super.supabaseUrl, super.supabaseKey);
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}