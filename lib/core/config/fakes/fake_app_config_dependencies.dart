import 'package:construculator_app_architecture/core/config/interfaces/app_config_interfaces.dart';

/// Fake implementation of IDotEnvLoader for testing
class FakeDotEnvLoader implements IDotEnvLoader {
  final Map<String, String?> _envVars = {};
  bool shouldThrowOnLoad = false;
  String? loadErrorMessage;
  String? lastLoadedFileName;

  @override
  Future<void> load({String? fileName}) async {
    if (shouldThrowOnLoad) {
      throw Exception(loadErrorMessage ?? 'Failed to load env file');
    }
    lastLoadedFileName = fileName;
  }

  @override
  String? get(String key) {
    return _envVars[key];
  }

  // Test helper methods
  void setEnvVar(String key, String? value) {
    _envVars[key] = value;
  }

  void clearEnvVars() {
    _envVars.clear();
  }

  void reset() {
    _envVars.clear();
    shouldThrowOnLoad = false;
    loadErrorMessage = null;
    lastLoadedFileName = null;
  }
}

/// Fake implementation of ILogger for testing
class FakeLogger implements ILogger {
  final List<String> loggedMessages = [];

  @override
  void info(String message) {
    loggedMessages.add(message);
  }

  // Test helper methods
  void clearLogs() {
    loggedMessages.clear();
  }

  bool hasLoggedMessage(String message) {
    return loggedMessages.any((log) => log.contains(message));
  }

  void reset() {
    loggedMessages.clear();
  }
}
