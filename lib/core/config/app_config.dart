import 'package:construculator/core/config/env_constants.dart';
import 'package:construculator/core/config/interfaces/app_config_interfaces.dart';
import 'package:construculator/core/logging/logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Default implementations
class DotEnvLoaderImpl implements DotEnvLoader {
  @override
  Future<void> load({String? fileName}) async {
    if (fileName != null) {
      await dotenv.load(fileName: fileName);
    } else {
      await dotenv.load();
    }
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

class AppConfigLoggerImpl implements AppLogger {
  final String tag;
  
  AppConfigLoggerImpl(this.tag);
  
  @override
  void info(String message) {
    Logger(tag).info(message);
  }
}

// NoOpLogger is a logger that does nothing - for testing
class NoOpLogger implements AppLogger {
  @override
  void info(String message) {
    // Do nothing - for testing
  }
}

class AppConfig {
  AppConfig._({
    DotEnvLoader? dotEnvLoader,
    SupabaseInitializer? supabaseInitializer,
    AppLogger? logger,
  }) : _dotEnvLoader = dotEnvLoader ?? DotEnvLoaderImpl(),
       _supabaseInitializer = supabaseInitializer ?? SupabaseInitializerImpl(),
       _logger = logger ?? AppConfigLoggerImpl("App-Config");

  static AppConfig? _instance;
  static AppConfig get instance => _instance ??= AppConfig._();

  // Factory from configuration - useful for testing with injected dependencies
  static AppConfig createFromConfig({
    DotEnvLoader? dotEnvLoader,
    SupabaseInitializer? supabaseInitializer,
    AppLogger? logger,
  }) {
    return AppConfig._(
      dotEnvLoader: dotEnvLoader,
      supabaseInitializer: supabaseInitializer,
      logger: logger,
    );
  }

  // Reset singleton for testing
  static void resetForTesting() {
    _instance = null;
  }

  final DotEnvLoader _dotEnvLoader;
  final SupabaseInitializer _supabaseInitializer;
  final AppLogger _logger;

  late Environment environment;
  late SupabaseClient supabaseClient;
  late String apiUrl;
  late String appName;
  late String baseAppName;
  late bool debugFeaturesEnabled;

  Future<void> initialize(Environment env) async {
    environment = env; // Set environment first, before any logging
    
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
