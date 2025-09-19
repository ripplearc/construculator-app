// coverage:ignore-file

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:construculator/libraries/annotations/data_model.dart';

/// A fake implementation of [supabase.Session] for testing purposes
@dataModel
class FakeSession implements supabase.Session {
  /// The supabase user
  @override
  final supabase.User user;

  /// The supabase access token
  @override
  final String accessToken;

  /// The supabase refresh token
  @override
  final String refreshToken;

  /// Creates a new [FakeSession]
  FakeSession({
    required this.user,
    this.accessToken = 'fake-access-token',
    this.refreshToken = 'fake-refresh-token',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
