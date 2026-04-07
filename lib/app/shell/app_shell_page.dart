import 'dart:async';

import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
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
  final AppShellBloc _bloc = Modular.get<AppShellBloc>();
  final CurrentProjectNotifier _currentProjectNotifier =
      Modular.get<CurrentProjectNotifier>();
  final TabModuleManager _moduleLoader = Modular.get<TabModuleManager>();

  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    ShellTab.values.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  StreamSubscription<String?>? _projectSubscription;
  StreamSubscription<ProjectDropdownState>? _dropdownSubscription;
  String? _projectId;

  @override
  void initState() {
    super.initState();
    _projectId = _currentProjectNotifier.currentProjectId;
    _projectSubscription = _currentProjectNotifier.onCurrentProjectChanged.listen((
      projectId,
    ) {
      if (!mounted) return;
      // TODO: Clean up this project switching logic. Consider making CostEstimationLandingPage reactive to CurrentProjectNotifier directly instead of rebuilding the Shell to avoid destroying the tab's navigator stack.
      setState(() {
        _projectId = projectId;
      });
    });

    _moduleLoader.ensureTabModuleLoaded(ShellTab.home).then((_) {
      if (!mounted) return;

      final dropdownBloc = Modular.get<ProjectDropdownBloc>();
      dropdownBloc.add(const ProjectDropdownStarted());

      _dropdownSubscription = dropdownBloc.stream.listen((state) {
        if (state is ProjectDropdownLoadSuccess) {
          final id = state.selectedProject?.id;
          if (id != null && id != _currentProjectNotifier.currentProjectId) {
            _currentProjectNotifier.setCurrentProjectId(id);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    _dropdownSubscription?.cancel();
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
        return EstimationModule.landingPage(projectId: projectId);
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
                final isActive = state.selectedTabIndex == index;
                return Offstage(
                  offstage: !isActive,
                  child: TickerMode(
                    enabled: isActive,
                    child: isLoaded
                        ? TabNavigator(
                            key: tab == ShellTab.estimation
                                ? ValueKey('estimation_$_projectId')
                                : ValueKey(tab.name),
                            navigatorKey: _tabNavigatorKeys[index],
                            rootBuilder: (_) => _buildTabRoot(tab),
                          )
                        : const SizedBox.shrink(),
                  ),
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
