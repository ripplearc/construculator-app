
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface for initializing Supabase.
///
/// The [initialize] method is used to initialize Supabase client.
/// The [url] and [anonKey] are required parameters that can be obtained from the supabase project dashboard.
/// The [debug] parameter is optional and defaults to false. It is used to enable debug mode.
abstract class SupabaseInitializer {
  Future<SupabaseClient> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  });
}