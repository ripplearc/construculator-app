// coverage:ignore-file
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake implementation of SupabaseClient for testing.
///
/// This class provides a minimal fake `SupabaseClient` primarily to satisfy type
/// requirements in tests where the actual Supabase interactions are not the focus.
/// 
/// Key points:
/// - **Simplicity**: It avoids implementing all `SupabaseClient` methods to keep the
///   fake lightweight and easy to maintain.
/// - **`noSuchMethod`**: Unimplemented methods will trigger `noSuchMethod`,
///   typically resulting in a `NoSuchMethodError` during tests if unexpected
///   client functionality is invoked.
/// - **Wrapper for Real Testing**: More comprehensive testing of Supabase interactions
///   (e.g., specific Auth, Postgrest calls) is intended to be done through a
///   more specialized wrapper, `FakeSupabaseWrapper`,
///   which would handle detailed method-level faking. This `FakeSupabaseClient`
///   is often returned by `FakeSupabaseInitializer` merely to confirm initialization flow.
class FakeSupabaseClient implements SupabaseClient {
  // By not overriding specific methods, any calls to them will fall through to
  // noSuchMethod. If a specific behavior is needed for a method, that method
  // can be explicitly implemented here or, preferably, in a more specialized fake.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}