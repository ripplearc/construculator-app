
import 'package:construculator/libraries/config/interfaces/supabase_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DefaultSupabaseInitializer implements SupabaseInitializer {
  @override
  Future<SupabaseClient> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: debug,
    );
    return Supabase.instance.client;
  }
}
