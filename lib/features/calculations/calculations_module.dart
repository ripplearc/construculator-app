import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CalculationsModule extends Module {
  CalculationsModule();

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculationsPage());
  }
}
