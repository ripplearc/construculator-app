import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/data/repositories/project_repository_impl.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/features/project/domain/usecases/get_project_usecase.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectModule extends Module {
  final AppBootstrap appBootstrap;
  ProjectModule(this.appBootstrap);

  @override
  List<Module> get imports => [ClockModule()];

  @override
  void routes(RouteManager r) {}

  @override
  void binds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<ProjectRepository>(() => ProjectRepositoryImpl());

  i.addLazySingleton<GetProjectUseCase>(() => GetProjectUseCase(i()));
}
