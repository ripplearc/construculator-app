import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CalculationsModule extends Module {
  final AppBootstrap appBootstrap;

  CalculationsModule(this.appBootstrap);

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculationsPage());
  }
}
