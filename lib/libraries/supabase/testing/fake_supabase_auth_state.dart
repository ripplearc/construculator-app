// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A fake implementation of [supabase.AuthState] for testing purposes
class FakeAuthState implements supabase.AuthState {
  /// The supabase auth change event
  @override
  final supabase.AuthChangeEvent event;

  /// The supabase session
  @override
  final supabase.Session? session;

  /// Creates a new [FakeAuthState]
  FakeAuthState({required this.event, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
