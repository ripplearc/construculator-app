/// Interface for loading environment variables from a file.
abstract class EnvLoader {
  /// The [load] method is used to load the environment variables from a file.
  Future<void> load({String? fileName});
  /// The [get] method is used to get a specific environment variable.
  String? get(String key);
}