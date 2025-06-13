import 'package:construculator/libraries/config/env_constants.dart';

/// Interface that abstracts configuration operations.
abstract class Config {
  /// Used to initialize any important services the app requires to run.
  /// 
  /// [env] is the environment to initialize the app for.
  Future<void> initialize(Environment env);

  /// Returns the name(eg. dev, qa, prod, etc) or alias(eg. fishfood, dogfood, etc) of the environment.
  /// 
  /// [env] is the environment to get the name or alias for.
  /// 
  /// [isAlias] is a flag to determine whether to return the name or alias of the environment.
  String getEnvironmentName(Environment env, {bool isAlias = false});

  bool get isDev;

  bool get isQa;

  bool get isProd;


  /// Represents the current environment of the application
  Environment get environment;

  /// This is the app name with the environement appened to it, eg. Contruculator - Fishfood
  /// It is the same as [baseAppName] in production
  String get appName;

  /// This is the app name without the appended environment
  String get baseAppName;

  /// Indicates whether debug features are enabled or not.
  bool get debugFeaturesEnabled;

}