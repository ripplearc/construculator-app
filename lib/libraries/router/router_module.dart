import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/modular_navigator_impl.dart';
import 'package:flutter_modular/flutter_modular.dart';

class RouterModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<AppRouter>(() => ModularRouterImpl());
  }
}