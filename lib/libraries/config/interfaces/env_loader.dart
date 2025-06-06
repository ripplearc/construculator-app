/// Interface for loading environment variables from a file.
///
/// The [load] method is used to load the environment variables from a file.
/// 
/// The [get] method is used to get a specific environment variable.
abstract class EnvLoader {
  Future<void> load({String? fileName});
  String? get(String key);
}