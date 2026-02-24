import 'dart:async';

import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/widgets/app_bottom_nav_bar.dart';
import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final AppShellBloc _bloc = AppShellBloc();
  final CurrentProjectNotifier _currentProjectNotifier =
      Modular.get<CurrentProjectNotifier>();

  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  StreamSubscription<String?>? _projectSubscription;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _projectId = _currentProjectNotifier.currentProjectId;
    _projectSubscription = _currentProjectNotifier.onCurrentProjectChanged
        .listen((projectId) {
          if (!mounted) {
            return;
          }
          setState(() {
            _projectId = projectId;
          });
        });
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _bloc.close();
    super.dispose();
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    final state = _bloc.state;
    final currentNavigator =
        _tabNavigatorKeys[state.selectedTabIndex].currentState;

    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return;
    }

    if (state.selectedTabIndex != 0) {
      _bloc.add(const AppShellTabSelected(0));
      return;
    }

    // Allow system to handle back (exit app)
    SystemNavigator.pop();
  }

  void _handleTabTap(int index) {
    _bloc.add(AppShellTabSelected(index));
  }

  Widget _buildTabRoot(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return const DashboardPage();
      case 1:
        return const CalculationsPage();
      case 2:
        final projectId = _projectId;
        if (projectId == null || projectId.isEmpty) {
          return const SizedBox.shrink();
        }
        return MultiBlocProvider(
          providers: [
            BlocProvider<CostEstimationListBloc>(
              create: (context) {
                return Modular.get<CostEstimationListBloc>()
                  ..add(CostEstimationListStartWatching(projectId: projectId));
              },
            ),
            BlocProvider(
              create: (context) => Modular.get<AddCostEstimationBloc>(),
            ),
            BlocProvider(
              create: (context) => Modular.get<DeleteCostEstimationBloc>(),
            ),
          ],
          child: CostEstimationLandingPage(
            projectId: projectId,
            showScaffold: false,
          ),
        );
      case 3:
        return const MembersPage();
      default:
        return const SizedBox.shrink();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      return AppBar(title: const Text('Construculator'), centerTitle: true);
    }

    return Modular.get<ProjectUIProvider>().buildProjectHeaderAppbar(
      projectId: projectId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppShellBloc, AppShellState>(
      bloc: _bloc,
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
          child: Scaffold(
            appBar: _buildAppBar(context),
            body: Stack(
              children: List.generate(4, (index) {
                final isLoaded = state.loadedTabIndexes.contains(index);
                return Offstage(
                  offstage: state.selectedTabIndex != index,
                  child: isLoaded
                      ? TabNavigator(
                          navigatorKey: _tabNavigatorKeys[index],
                          rootBuilder: (_) => _buildTabRoot(index),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ),
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: state.selectedTabIndex,
              onTap: (index) => _handleTabTap(index),
            ),
          ),
        );
      },
    );
  }
}
