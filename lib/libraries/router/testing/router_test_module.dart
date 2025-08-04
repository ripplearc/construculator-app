import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/testing/fake_router.dart';
import 'package:flutter_modular/flutter_modular.dart';

class RouterTestModule extends Module {
  @override
  void exportedBinds(Injector i) {
    i.addSingleton<AppRouter>(() => FakeAppRouter());
  }
}