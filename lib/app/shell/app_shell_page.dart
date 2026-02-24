import 'dart:async';

import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/presentation/bloc/add_cost_estimation_bloc/add_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/cost_estimation_list_bloc/cost_estimation_list_bloc.dart';
import 'package:construculator/features/estimation/presentation/bloc/delete_cost_estimation_bloc/delete_cost_estimation_bloc.dart';
import 'package:construculator/features/estimation/presentation/pages/cost_estimation_landing_page.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final AppShellBloc _bloc = AppShellBloc();
  final CurrentProjectNotifier _currentProjectNotifier =
      Modular.get<CurrentProjectNotifier>();
  final TabModuleManager _moduleLoader = Modular.get<TabModuleManager>();

  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    ShellTab.values.length,
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
          if (!mounted) return;
          setState(() {
            _projectId = projectId;
          });
        });
    _moduleLoader.ensureTabModuleLoaded(ShellTab.home);
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

    SystemNavigator.pop();
  }

  Future<void> _handleTabTap(int index) async {
    final tab = ShellTab.values[index];
    await _moduleLoader.ensureTabModuleLoaded(tab);
    _bloc.add(AppShellTabSelected(index));
  }

  Widget _buildTabRoot(ShellTab tab) {
    if (!_moduleLoader.isLoaded(tab)) {
      return const Center(child: CircularProgressIndicator());
    }
    switch (tab) {
      case ShellTab.home:
        return const DashboardPage();
      case ShellTab.calculations:
        return const CalculationsPage();
      case ShellTab.estimation:
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
          child: CostEstimationLandingPage(projectId: projectId),
        );
      case ShellTab.members:
        return const MembersPage();
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final projectId = _projectId;
    if (projectId == null || projectId.isEmpty) {
      final coreColors = Theme.of(context).coreColors;
      return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: coreColors.pageBackground,
            boxShadow: CoreShadows.medium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: CoreSpacing.space4,
            vertical: CoreSpacing.space2,
          ),
          child: AppBar(
            backgroundColor: coreColors.pageBackground,
            elevation: 0,
            centerTitle: true,
            titleSpacing: 0,
            title: Text(context.l10n.appTitle),
          ),
        ),
      );
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
              children: List.generate(ShellTab.values.length, (index) {
                final tab = ShellTab.values[index];
                final isLoaded = state.loadedTabIndexes.contains(index);
                return Offstage(
                  offstage: state.selectedTabIndex != index,
                  child: isLoaded
                      ? TabNavigator(
                          navigatorKey: _tabNavigatorKeys[index],
                          rootBuilder: (_) => _buildTabRoot(tab),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(CoreSpacing.space4),
              child: CoreBottomNavBar(
                tabs: [
                  BottomNavTab(
                    icon: CoreIcons.home,
                    label: context.l10n.homeTab,
                  ),
                  BottomNavTab(
                    icon: CoreIcons.calculate,
                    label: context.l10n.calculationsTab,
                  ),
                  BottomNavTab(
                    icon: CoreIcons.cost,
                    label: context.l10n.costEstimation,
                  ),
                  BottomNavTab(
                    icon: CoreIcons.members,
                    label: context.l10n.membersTab,
                  ),
                ],
                selectedIndex: state.selectedTabIndex,
                onTabSelected: _handleTabTap,
              ),
            ),
          ),
        );
      },
    );
  }
}
