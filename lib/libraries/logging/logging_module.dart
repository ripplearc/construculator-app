import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Module responsible for providing the application logger.
class LoggingModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addLazySingleton<AppLogger>(() => AppLogger());
  }
}

