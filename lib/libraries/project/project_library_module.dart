import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/project/data/current_project_notifier_impl.dart';
import 'package:construculator/libraries/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectLibraryModule extends Module {
  final AppBootstrap appBootstrap;
  ProjectLibraryModule(this.appBootstrap);

  @override
  List<Module> get imports => [ClockModule()];

  @override
  void routes(RouteManager r) {}

  @override
  void exportedBinds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<CurrentProjectNotifier>(
    () => CurrentProjectNotifierImpl(
      initialProjectId: '950e8400-e29b-41d4-a716-446655440001',
    ),
  );

  i.addLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl());
}
