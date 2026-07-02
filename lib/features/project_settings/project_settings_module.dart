import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/project_settings/presentation/bloc/project_settings_bloc/project_settings_bloc.dart';
import 'package:construculator/features/project_settings/presentation/pages/create_project_screen.dart';
import 'package:construculator/features/project_settings/presentation/pages/edit_project_screen.dart';
import 'package:construculator/features/project_settings/presentation/pages/project_detail_screen.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/guards/auth_guard.dart';
import 'package:construculator/libraries/router/routes/project_settings_routes.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// DI-binding module for the Project Settings feature used by test harnesses.
///
/// **Production note:** this class is NOT mounted by [ShellModule]. The live
/// route registrations live in [ProjectSettingsRoutesModule], which [ShellModule]
/// mounts instead. The [routes] override below mirrors those registrations so
/// that test harnesses importing this module can navigate to
/// [ProjectDetailScreen] without blowing up. If [ProjectSettingsRoutesModule]
/// changes its route definitions, update [routes] here to stay in sync.
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
    r.child(editProjectChildRoute, child: (_) => const EditProjectScreen());
    r.child(createProjectChildRoute, child: (_) => const CreateProjectScreen());
  }
}
