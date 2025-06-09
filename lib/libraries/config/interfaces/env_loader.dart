/// Interface for loading environment variables from a file.
abstract class EnvLoader {
  /// Used to load the environment variables from a file.
  /// 
  /// [fileName] is the name of the file to load the environment variables from.
  Future<void> load({String? fileName});

  /// Used to get a specific environment variable.
  /// 
  /// [key] is the key of the environment variable to get.
  String? get(String key);
}