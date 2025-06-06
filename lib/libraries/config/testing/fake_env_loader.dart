import 'package:construculator/libraries/config/interfaces/env_loader.dart';

/// Fake implementation of EnvLoader for testing
class FakeEnvLoader implements EnvLoader {
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
    if (fileName == null || !fileName.contains(_envVars['APP_ENV_FILE_INDICATOR'] ?? 'unique_string_never_found')) {
    }
  }

  @override
  String? get(String key) {
    return _envVars[key];
  }

  // Test helper methods, sets env vars for testing
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