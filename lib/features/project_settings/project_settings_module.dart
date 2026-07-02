import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Modular module owning Tier-1 routes and shared bindings for the Project Settings feature.
///
/// Registers [ProjectDetailScreen] behind an [AuthGuard] and provides
/// [ProjectSettingsBloc] for downstream screens.
class ProjectSettingsModule extends Module {
  final AppBootstrap appBootstrap;

  ProjectSettingsModule(this.appBootstrap);

  @override
  List<Module> get imports => [ProjectLibraryModule(appBootstrap)];

  @override
  void binds(Injector i) {
    i.add<ProjectSettingsBloc>(
      () => ProjectSettingsBloc(repository: i()),
    );
  }

  @override
  void routes(RouteManager r) {
    r.child(
      viewProjectRoute,
      guards: [AuthGuard(() => Modular.get<AuthManager>())],
      child: (_) => const ProjectDetailScreen(),
    );
  }
}
