import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

class AppConfigImpl implements Config {
  AppConfigImpl({
    required EnvLoader envLoader,
  }) : _envLoader = envLoader,
       _logger = AppLogger().tag("AppConfig");

  final EnvLoader _envLoader;
  final AppLogger _logger;

  @override
  late Environment environment;
  @override
  late String apiUrl;
  @override
  late String appName;
  @override
  late String baseAppName;
  @override
  late bool debugFeaturesEnabled;

  @override
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
    await _envLoader.load(fileName: "assets/env/$envFileName");
    _logger.info('Loaded environment-specific config: $envFileName');

    baseAppName = _envLoader.get('APP_NAME') ?? 'Construculator';
    apiUrl = _envLoader.get('API_URL') ?? '';

    debugFeaturesEnabled = environment != Environment.prod;

    if (environment == Environment.prod) {
      appName = baseAppName;
    } else {
      appName = '$baseAppName (${getEnvironmentName(environment, isAlias: true)})';
    }
    _logger.emoji('🚀').info('AppConfig initialized for ${getEnvironmentName(environment)}');
    _logger.emoji('🔌').info('API URL: $apiUrl');
    _logger.emoji('📱').info('App Name: $appName');
  }

  @override
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

  @override
  bool get isDev => environment == Environment.dev;

  @override
  bool get isQa => environment == Environment.qa;

  @override
  bool get isProd => environment == Environment.prod;
}
