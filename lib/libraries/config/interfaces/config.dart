import 'package:construculator/libraries/config/env_constants.dart';

/// Interface that abstracts configuration operations.
/// 
/// [initialize] is used to initialize any important services the app requires to run.
/// 
/// [getEnvironmentName] is used to get the name(eg. dev, qa, prod, etc) or alias(eg. fishfood, dogfood, etc) of the environment.
abstract class Config {
  late Environment environment;
  late String apiUrl;
  late String appName;
  late String baseAppName;
  late bool debugFeaturesEnabled;

  Future<void> initialize(Environment env);

  String getEnvironmentName(Environment env, {bool isAlias = false});

  bool get isDev;

  bool get isQa;

  bool get isProd;
}