import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/interfaces/logger.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppConfig {
  AppConfig({
    required EnvLoader dotEnvLoader,
    required SupabaseInitializer supabaseInitializer,
    required Logger logger,
  }) : _dotEnvLoader = dotEnvLoader,
       _supabaseInitializer = supabaseInitializer,
       _logger = logger.tag("AppConfig");

  final EnvLoader _dotEnvLoader;
  final SupabaseInitializer _supabaseInitializer;
  final Logger _logger;

  late Environment environment;
  late SupabaseClient supabaseClient;
  late String apiUrl;
  late String appName;
  late String baseAppName;
  late bool debugFeaturesEnabled;

  Future<void> initialize(Environment env) async {
    environment = env;
    String envFileName;
    switch (environment) {
      case Environment.dev:
        envFileName = '.env.dev';
        break;
      case Environment.qa:
        envFileName = '.env.qa';
        break;
      case Environment.prod:
        envFileName = '.env.prod';
        break;
    }
    await _dotEnvLoader.load(fileName: "assets/env/$envFileName");
    _logger.info('Loaded environment-specific config: $envFileName');

    baseAppName = _dotEnvLoader.get('APP_NAME') ?? 'Construculator';
    apiUrl = _dotEnvLoader.get('API_URL') ?? '';

    debugFeaturesEnabled = environment != Environment.prod;

    if (environment == Environment.prod) {
      appName = baseAppName;
    } else {
      appName = '$baseAppName (${getEnvironmentName(environment, isAlias: true)})';
    }
    
    supabaseClient = await _initializeSupabaseClient();
    _logger.emoji('🚀').info('AppConfig initialized for ${getEnvironmentName(environment)}');
    _logger.emoji('🔌').info('API URL: $apiUrl');
    _logger.emoji('📱').info('App Name: $appName');
  }

  Future<SupabaseClient> _initializeSupabaseClient() async {
    final supabaseUrl = _dotEnvLoader.get('SUPABASE_URL') ?? '';
    final supabaseAnonKey = _dotEnvLoader.get('SUPABASE_ANON_KEY') ?? '';
    _logger.info('Supabase URL: $supabaseUrl');
    
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      _logger.error('Supabase URL or Anon Key is missing in the loaded .env files.');
      throw Exception(
        'Supabase configuration is missing. Check your .env files.',
      );
    }
    
    _logger.info('Initializing Supabase');
    return await _supabaseInitializer.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: debugFeaturesEnabled,
    );
  }

  String getEnvironmentName(Environment env, {bool isAlias = false}) {
    switch (env) {
      case Environment.dev:
        return isAlias ? devAlias : devReadableName;
      case Environment.qa:
        return isAlias ? qaAlias : qaReadableName;
      case Environment.prod:
        return isAlias ? prodAlias : prodReadableName;
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isQa => environment == Environment.qa;
  bool get isProd => environment == Environment.prod;
}
