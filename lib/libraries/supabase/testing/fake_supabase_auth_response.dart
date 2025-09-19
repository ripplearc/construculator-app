// coverage:ignore-file

import 'package:construculator/libraries/annotations/data_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A fake implementation of [supabase.AuthResponse] for testing purposes
@dataModel
class FakeAuthResponse implements supabase.AuthResponse {
  /// The supabase user
  @override
  final supabase.User? user;

  /// The supabase session
  @override
  final supabase.Session? session;

  /// Creates a new [FakeAuthResponse]
  FakeAuthResponse({this.user, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A fake implementation of [supabase.UserResponse] for testing purposes
@dataModel
class FakeUserResponse implements supabase.UserResponse {
  /// The supabase user
  @override
  final supabase.User? user;

  /// Creates a new [FakeUserResponse]
  FakeUserResponse({this.user});

  /// Creates a new [FakeUserResponse]
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
