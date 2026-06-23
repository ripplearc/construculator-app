import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/libraries/project/bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_creation_screen.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module owning Tier-1 (full-screen) routes for the Project Settings feature.
///
/// Imports [ProjectLibraryModule] for shared data-layer bindings, and registers
/// the [ProjectCreationScreen] route behind an [AuthGuard].
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
  }
}
