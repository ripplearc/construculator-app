import 'package:construculator/core/config/env_constants.dart';
import 'package:construculator/core/config/interfaces/app_config_interfaces.dart';
import 'package:construculator/core/libraries/logging/interfaces/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Default implementations
class DotEnvLoaderImpl implements DotEnvLoader {
  // Keep track of loaded files to avoid reloading the same one if not necessary,
  // or ensure .env is loaded before .env.specific
  final Set<String> _loadedFiles = {};

  @override
  Future<void> load({String? fileName}) async {
    final String effectiveFileName = fileName ?? '.env'; // Ensures it's non-null

    // Avoid reloading the default '.env' if it was already loaded, 
    // but always reload specific files if explicitly asked.
    if (_loadedFiles.contains(effectiveFileName) && effectiveFileName == '.env') {
      return; // Already loaded default .env, do nothing
    }

    if (effectiveFileName == '.env') {
      await dotenv.load(); // Loads the default .env file
    } else {
      await dotenv.load(fileName: effectiveFileName); // Loads the specified file
    }
    _loadedFiles.add(effectiveFileName);
  }

  @override
  String? get(String key) {
    return dotenv.env[key];
  }
}

class SupabaseInitializerImpl implements SupabaseInitializer {
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

class AppConfig {
  // Constructor now requires dependencies and is public.
  // Singleton pattern and default initializers are removed.
  AppConfig({
    required DotEnvLoader dotEnvLoader,
    required SupabaseInitializer supabaseInitializer,
    required AppLogger logger,
  }) : _dotEnvLoader = dotEnvLoader,
       _supabaseInitializer = supabaseInitializer,
       _logger = logger.tag("AppConfig");

  // Static instance, instance getter, createFromConfig factory, and resetForTesting are removed
  // as Modular will manage AppConfig as a singleton.

  final DotEnvLoader _dotEnvLoader;
  final SupabaseInitializer _supabaseInitializer;
  final AppLogger _logger;

  late Environment environment;
  late SupabaseClient supabaseClient;
  late String apiUrl;
  late String appName;
  late String baseAppName;
  late bool debugFeaturesEnabled;

  Future<void> initialize() async {
    // 1. Load the default .env file to get APP_ENV
    // Assuming DotEnvLoader.load() without filename loads default '.env'
    await _dotEnvLoader.load(); 
    final appEnvStr = _dotEnvLoader.get('APP_ENV');

    if (appEnvStr == null) {
      _logger.error('APP_ENV not found in .env file. Defaulting to Environment.dev.');
      environment = Environment.dev; // Default or throw error
    } else {
      switch (appEnvStr.toLowerCase()) {
        case 'dev':
          environment = Environment.dev;
          break;
        case 'qa':
          environment = Environment.qa;
          break;
        case 'prod':
          environment = Environment.prod;
          break;
        default:
          _logger.warning('Unknown APP_ENV value: $appEnvStr. Defaulting to Environment.dev.');
          environment = Environment.dev; // Default or throw error
      }
    }
    _logger.info('Runtime Environment determined from APP_ENV: ${getEnvironmentName(environment)}');

    // 2. Load the environment-specific .env file
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
    
    // Pass the full path to the environment-specific file
    await _dotEnvLoader.load(fileName: "assets/env/$envFileName");
    _logger.info('Loaded environment-specific config: $envFileName');

    // 3. Continue with existing initialization logic
    baseAppName = _dotEnvLoader.get('APP_NAME') ?? 'MyApp';
    apiUrl = _dotEnvLoader.get('API_URL') ?? '';

    debugFeaturesEnabled = environment != Environment.prod;

    if (environment == Environment.prod) {
      appName = baseAppName;
    } else {
      appName = '$baseAppName (${getEnvironmentName(environment)})';
    }
    
    supabaseClient = await _initializeSupabaseClient();
    _logger.info('🚀 AppConfig initialized for ${getEnvironmentName(environment)}');
    _logger.info('🔌 API URL: $apiUrl');
    _logger.info('📱 App name: $appName');
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

  String getEnvironmentName(Environment env) {
    switch (env) {
      case Environment.dev:
        return devReadableName;
      case Environment.qa:
        return qaReadableName;
      case Environment.prod:
        return prodReadableName;
    }
  }

  bool get isDev => environment == Environment.dev;
  bool get isQa => environment == Environment.qa;
  bool get isProd => environment == Environment.prod;
}
