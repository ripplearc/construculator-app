import 'package:construculator/features/project_settings/domain/usecases/get_project_usecase.dart';
import 'package:construculator/features/project_settings/domain/repositories/project_repository.dart';
import 'package:construculator/features/project_settings/data/repositories/project_repository_impl.dart';
import 'package:construculator/app/app_bootstrap.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectSettingsModule extends Module {
  final AppBootstrap appBootstrap;
  ProjectSettingsModule(this.appBootstrap);

  @override
  List<Module> get imports => [];

  @override
  void routes(RouteManager r) {}

  @override
  void binds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<ProjectRepository>(
    () => RemoteProjectRepository(),
  );

  i.addLazySingleton<GetProjectUseCase>(
    () => GetProjectUseCase(i()),
  );
}
