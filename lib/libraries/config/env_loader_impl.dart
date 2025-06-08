import 'package:construculator/libraries/config/interfaces/env_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Default implementation of EnvLoader using the flutter_dotenv package
class EnvLoaderImpl implements EnvLoader {
  @override
  Future<void> load({String? fileName}) async {
    if (fileName == null) {
      await dotenv.load();
    } else {
      await dotenv.load(fileName: fileName);
    }
  }

  @override
  String? get(String key) {
    return dotenv.env[key];
  }
}
