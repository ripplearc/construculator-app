import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/default_tab_providers.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/dashboard_module.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Minimal Modular module for widget tests that need [DashboardModule] and
/// a fully-wired [AppShellBloc] without loading any real feature modules.
class DashboardShellTestModule extends Module {
  final AppBootstrap appBootstrap;

  DashboardShellTestModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    DashboardModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
  ];

  @override
  void binds(Injector i) {
    i.addLazySingleton<TabModuleManager>(
      () => TabModuleManager(
        appBootstrap,
        providers: {
          for (final tab in ShellTab.values) tab: const NoOpTabModuleProvider(),
        },
      ),
    );
    i.addLazySingleton<AppShellBloc>(
      () => AppShellBloc(moduleLoader: i.get()),
    );
    i.addLazySingleton<ProjectDropdownBloc>(
      () => ProjectDropdownBloc(
        projectRepository: i(),
        authManager: i(),
      ),
    );
    i.add<WatchRecentEstimationsUseCase>(
      () => WatchRecentEstimationsUseCase(i(), i()),
    );
    i.addLazySingleton<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase: i(),
        currentProjectNotifier: i(),
      ),
    );
  }
}
