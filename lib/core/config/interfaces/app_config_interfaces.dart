// These are are specific to app_config, makes app config easier to test
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DotEnvLoader {
  Future<void> load({String? fileName});
  String? get(String key);
}

abstract class AppLogger {
  void info(String message);
}
abstract class SupabaseInitializer {
  Future<SupabaseClient> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  });
}