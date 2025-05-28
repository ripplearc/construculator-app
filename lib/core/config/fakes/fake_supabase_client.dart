// coverage:ignore-file
import 'package:supabase_flutter/supabase_flutter.dart';
/// Fake implementation of SupabaseClient for testing
class FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}