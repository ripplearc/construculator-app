import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/calculator/data/repositories/calculator_preferences_repository_impl.dart';
import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/features/calculator/presentation/pages/calculator_page.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// The calculator feature: its page and the settings repository it reads,
/// which follows the signed-in profile through the auth library.
class CalculatorModule extends Module {
  /// The app's shared bootstrap, handed on to the imported
  /// [AuthLibraryModule] so the repository sees the same auth state as the
  /// rest of the app.
  final AppBootstrap appBootstrap;

  /// Creates the module over the app's [appBootstrap].
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
