import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:construculator/libraries/errors/exceptions.dart';
import 'package:stack_trace/stack_trace.dart';

/// Fake implementation of EnvLoader for testing
class FakeEnvLoader implements EnvLoader {
  final Map<String, String?> _envVars = {};

  /// If true, will throw an exception when load is called
  bool shouldThrowOnLoad = false;

  /// The error message to throw if shouldThrowOnLoad is true
  String? loadErrorMessage;

  /// The last file name that was loaded
  String? lastLoadedFileName;

  @override
  Future<void> load({String? fileName}) async {
    if (shouldThrowOnLoad) {
      throw ConfigException(Trace.current(), loadErrorMessage ?? 'Failed to load env file');
    }
    lastLoadedFileName = fileName;
    if (fileName == null || !fileName.contains(_envVars['APP_ENV_FILE_INDICATOR'] ?? 'unique_string_never_found')) {
    }
  }

  @override
  String? get(String key) {
    return _envVars[key];
  }

  /// Test helper methods, sets env vars for testing
  /// 
  /// [key] is the key of the environment variable to set.
  /// 
  /// [value] is the value of the environment variable to set.
  void setEnvVar(String key, String? value) {
    _envVars[key] = value;
  }

  /// Test helper methods, clears all env vars for testing
  void clearEnvVars() {
    _envVars.clear();
  }

  /// Test helper methods, resets the env loader to its initial state
  void reset() {
    _envVars.clear();
    shouldThrowOnLoad = false;
    loadErrorMessage = null;
    lastLoadedFileName = null;
  }
}