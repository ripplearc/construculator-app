// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FakeAuthState implements supabase.AuthState {
  @override
  final supabase.AuthChangeEvent event;
  
  @override
  final supabase.Session? session;

  FakeAuthState({required this.event, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
} 