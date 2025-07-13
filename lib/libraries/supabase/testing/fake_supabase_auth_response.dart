// coverage:ignore-file

import 'package:construculator/libraries/annotations/data_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

@dataModel
class FakeAuthResponse implements supabase.AuthResponse {
  @override
  final supabase.User? user;
  
  @override
  final supabase.Session? session;

  FakeAuthResponse({this.user, this.session});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}