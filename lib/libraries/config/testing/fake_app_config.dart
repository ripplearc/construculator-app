import 'package:construculator/libraries/config/env_constants.dart';
import 'package:construculator/libraries/config/interfaces/config.dart';

/// Fake implementation of [Config] for testing purposes with configurable behavior.
class FakeAppConfig implements Config {
  Environment _environment = Environment.dev;
  String _appName = 'Construculator';
  String _baseAppName = 'Construculator';
  bool _debugFeaturesEnabled = true;

  /// Sets the environment for the fake config.
  /// 
  /// [environment] the environment to set, eg. Evironment.dev
  void setEnvironment(Environment environment) {
    _environment = environment;
    _debugFeaturesEnabled = environment != Environment.prod;
  }

  /// Sets the app name for the fake config.
  /// 
  /// [appName] is the app name to set
  void setAppName(String appName) {
    _appName = appName;
  }

  /// Sets the base app name for the fake config.
  /// 
  /// [baseAppName] is the base app name to set
  void setBaseAppName(String baseAppName) {
    _baseAppName = baseAppName;
  }

  /// Sets whether debug features are enabled for the fake config.
  /// 
  /// [enabled] indicates whether or not debug should be enabled
  void setDebugFeaturesEnabled(bool enabled) {
    _debugFeaturesEnabled = enabled;
  }

  @override
  Future<void> initialize(Environment env) async {
    throw UnimplementedError();
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