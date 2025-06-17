// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class FakeAuthResponse implements supabase.AuthResponse {
  @override
  final supabase.User? user;
  
  @override
  final supabase.Session? session;

  FakeAuthResponse({this.user, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}