import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Flutter Modular module for the Calculations feature.
///
/// Registers the root route pointing to [CalculationsPage].
class CalculationsModule extends Module {
  CalculationsModule();

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculationsPage());
  }
}
