import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';
import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/logging/app_logger.dart';

class AppConfigImpl implements Config {
  AppConfigImpl({required EnvLoader envLoader})
    : _envLoader = envLoader,
      _logger = AppLogger().tag('AppConfig');

  final EnvLoader _envLoader;
  final AppLogger _logger;

  late Environment _environment;
  late String _appName;
  late String _baseAppName;
  late bool _debugFeaturesEnabled;

  @override
  Future<void> initialize(Environment env) async {
    _environment = env;
    String envFileName;
    switch (_environment) {
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
    await _envLoader.load(fileName: 'assets/env/$envFileName');
    _logger.info('Loaded environment-specific config: $envFileName');

    _baseAppName = _envLoader.get('APP_NAME') ?? 'Construculator';
    _debugFeaturesEnabled = _environment != Environment.prod;

    if (_environment == Environment.prod) {
      _appName = _baseAppName;
    } else {
      _appName =
          '$_baseAppName (${getEnvironmentName(_environment, isAlias: true)})';
    }
    _logger
        .emoji('🚀')
        .info('AppConfig initialized for ${getEnvironmentName(environment)}');
    _logger.emoji('📱').info('App Name: $_appName');
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
  bool get isDev => _environment == Environment.dev;

  @override
  bool get isQa => _environment == Environment.qa;

  @override
  bool get isProd => _environment == Environment.prod;

  @override
  Environment get environment => _environment;

  @override
  String get appName => _appName;

  @override
  String get baseAppName => _baseAppName;

  @override
  bool get debugFeaturesEnabled => _debugFeaturesEnabled;
}
