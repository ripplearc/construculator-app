import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project/presentation/bloc/get_project_bloc/get_project_bloc.dart';
import 'package:construculator/features/project/presentation/project_ui_provider_impl.dart';
import 'package:construculator/features/project/domain/usecases/get_project_usecase.dart';
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
  ];

  @override
  void routes(RouteManager r) {}

  @override
  void binds(Injector i) => _registerDependencies(i);
}

void _registerDependencies(Injector i) {
  i.addLazySingleton<ProjectUIProvider>(() => ProjectUIProviderImpl());

  i.addLazySingleton<GetProjectUseCase>(() => GetProjectUseCase(i()));

  i.add<GetProjectBloc>(() => GetProjectBloc(getProjectUseCase: i()));
}
