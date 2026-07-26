import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CalculatorModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculatorPage());
  }
}
