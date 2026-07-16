import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/edit_project_screen.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module owning routes for the Project Settings feature.
///
/// Imports [ProjectLibraryModule] for shared data-layer bindings, and registers
/// [ProjectCreationScreen] and [ProjectDetailScreen] routes behind [AuthGuard].
class ProjectSettingsRoutesModule extends Module {
  final AppBootstrap appBootstrap;
  ProjectSettingsRoutesModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.add<ProjectSettingsBloc>(
      () => ProjectSettingsBloc(repository: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      createProjectChildRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => BlocProvider(
        create: (_) => Modular.get<ProjectSettingsBloc>(),
        child: ProjectCreationScreen(
          authManager: Modular.get<AuthManager>(),
        ),
      ),
    );
    r.child(
      viewProjectRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => const ProjectDetailScreen(),
    );
    r.child(
      editProjectChildRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => const EditProjectScreen(),
    );
  }
}
