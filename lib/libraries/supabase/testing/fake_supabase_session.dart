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