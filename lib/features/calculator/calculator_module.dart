import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class CalculatorModule extends Module {
  final AppBootstrap appBootstrap;

  CalculatorModule(this.appBootstrap);

  @override
  List<Module> get imports => [AuthLibraryModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.addLazySingleton<CalculatorPreferencesRepository>(
      () => CalculatorPreferencesRepositoryImpl(
        authNotifier: i(),
        authManager: i(),
      ),
      config: BindConfig(onDispose: (repository) => repository.dispose()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const CalculatorPage());
  }
}
