import 'package:construculator/libraries/config/env_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Interface that abstracts configuration operations.
abstract class Config {
  late Environment environment;
  late SupabaseClient supabaseClient;
  late String apiUrl;
  late String appName;
  late String baseAppName;
  late bool debugFeaturesEnabled;

  /// Initializes the configuration with the given environment.
  Future<void> initialize(Environment env);

  /// Returns the name or alias of the environment.
  String getEnvironmentName(Environment env, {bool isAlias = false});

  /// Returns true if the environment is development.
  bool get isDev;

  /// Returns true if the environment is QA.
  bool get isQa;

  /// Returns true if the environment is production.
  bool get isProd;
}