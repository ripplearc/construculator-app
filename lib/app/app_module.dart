import 'package:construculator_app_architecture/core/core_module.dart';
import 'package:flutter_modular/flutter_modular.dart';
class AppModule extends Module {
  @override
  List<Module> get imports => [CoreModule()];

  @override
  void routes(RouteManager r) {
   // setup routes here
  }
}
