import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/domain/usecases/get_project_header_usecase.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_repository.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/time/clock_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ProjectModule extends Module {
  final AppBootstrap appBootstrap;
  ProjectModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    ClockModule(),
    ProjectLibraryModule(appBootstrap),
    AuthLibraryModule(appBootstrap),
  ];

  @override
  void routes(RouteManager r) {}

  @override
  void binds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<ProjectUIProvider>(
    () => ProjectUIProviderImpl(
      getProjectBlocBuilder: () => i.get<GetProjectBloc>(),
    ),
  );

  i.add<GetProjectBloc>(
    () => GetProjectBloc(
      getProjectHeaderUseCase: Modular.get<GetProjectHeaderUseCase>(),
      currentProjectNotifier: Modular.get<CurrentProjectNotifier>(),
    ),
  );
}

/// Adds the project-header objects that belong to one signed-in user: the use
/// case that holds the project repository.
///
/// Only the session module calls this, so a new use case is built for the next
/// user.
void registerProjectHeaderPerUserObjects(Injector i) =>
    _registerPerUserObjects(i);

void _registerPerUserObjects(Injector i) {
  i.addLazySingleton<GetProjectHeaderUseCase>(
    () => GetProjectHeaderUseCase(
      Modular.get<ProjectRepository>(),
      Modular.get<AuthRepository>(),
    ),
  );
}
