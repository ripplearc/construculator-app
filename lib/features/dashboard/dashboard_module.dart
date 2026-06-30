import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final AppBootstrap appBootstrap;
  DashboardModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    RouterModule(),
  ];

  @override
  void binds(Injector i) {
    i.add<DashboardBloc>(
      () => DashboardBloc(
        projectRepository: i(),
        currentProjectNotifier: i(),
        authNotifier: i(),
        authManager: i(),
      ),
    );
    i.add<ProjectSearchBloc>(
      () => ProjectSearchBloc(repository: i(), authManager: i()),
    );
  }
}
