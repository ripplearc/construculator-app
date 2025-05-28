// These are are specific to app_config, makes app config easier to test
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class IDotEnvLoader {
  Future<void> load({String? fileName});
  String? get(String key);
}

abstract class ILogger {
  void info(String message);
}
abstract class ISupabaseInitializer {
  Future<SupabaseClient> initialize({
    required String url,
    required String anonKey,
    bool debug = false,
  });
}