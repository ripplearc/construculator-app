import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/presentation/pages/splash_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SplashModule extends Module {
  final AppBootstrap appBootstrap;
  SplashModule(this.appBootstrap);

  @override
  void routes(RouteManager r) {
    r.child(
      '/',
      child: (context) => const SplashPage(),
    );
  }
}
