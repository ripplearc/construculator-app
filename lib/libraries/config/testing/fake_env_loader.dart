import 'package:construculator/libraries/config/interfaces/env_loader.dart';

/// Fake implementation of EnvLoader for testing
/// 
/// [shouldThrowOnLoad] - if true, will throw an exception when load is called
/// [loadErrorMessage] - the error message to throw if shouldThrowOnLoad is true
/// [lastLoadedFileName] - the last file name that was loaded
/// 
/// [setEnvVar] - sets an env var for testing
/// [clearEnvVars] - clears all env vars
/// [reset] - resets the env loader to its initial state
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