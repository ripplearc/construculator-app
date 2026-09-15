import 'package:construculator/app/app_bootstrap.dart';
import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/features/dashboard/presentation/bloc/dashboard_bloc/dashboard_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_search_bloc/project_search_bloc.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/libraries/auth/auth_library_module.dart';
import 'package:construculator/libraries/estimation/estimation_library_module.dart';
import 'package:construculator/libraries/owner/owner_library_module.dart';
import 'package:construculator/libraries/project/project_library_module.dart';
import 'package:construculator/libraries/router/router_module.dart';
import 'package:construculator/libraries/tag/tag_library_module.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class DashboardModule extends Module {
  final AppBootstrap appBootstrap;
  DashboardModule(this.appBootstrap);

  @override
  List<Module> get imports => [
    AuthLibraryModule(appBootstrap),
    ProjectLibraryModule(appBootstrap),
    TagLibraryModule(appBootstrap),
    OwnerLibraryModule(appBootstrap),
    EstimationLibraryModule(appBootstrap),
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
      () => ProjectSearchBloc(
        repository: i(),
        authManager: i(),
        tagRepository: i(),
        ownerRepository: i(),
      ),
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
    i.add<RecentEstimationsBloc>(
      () => RecentEstimationsBloc(
        watchRecentEstimationsUseCase: i(),
        currentProjectNotifier: i(),
      ),
    );
  }

  /// Wraps [child] in the dashboard-domain BLoC providers the app shell
  /// mounts above `AppShellPage`.
  ///
  /// `ShellModule` owns navigation and delegates this provider scope to the
  /// dashboard feature, mirroring `AppHeaderModule.buildHeader`. All three
  /// BLoCs are bound in [DashboardModule], which the shell imports.
  ///
  /// [DashboardBloc] and [RecentEstimationsBloc] are created here and start
  /// their watches on creation (`DashboardStarted` /
  /// `RecentEstimationsWatchStarted`).
  ///
  /// [ProjectDropdownBloc] is provided by value as the DI lazy singleton and
  /// is never re-created. Its `ProjectDropdownStarted` dispatch is owned by
  /// `AppShellPage.initState` instead, guarded so a remount cannot restart an
  /// already-loaded watch. Dispatching it from this seam would re-run every
  /// time the route's child builder re-evaluates and reset the user's project
  /// selection (CA-900).
  static Widget buildDashboardScope({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (_) =>
              Modular.get<DashboardBloc>()..add(const DashboardStarted()),
        ),
        BlocProvider<ProjectDropdownBloc>.value(
          value: Modular.get<ProjectDropdownBloc>(),
        ),
        BlocProvider<RecentEstimationsBloc>(
          create: (_) => Modular.get<RecentEstimationsBloc>()
            ..add(const RecentEstimationsWatchStarted()),
        ),
      ],
      child: child,
    );
  }
}
