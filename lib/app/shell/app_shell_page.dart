import 'dart:async';

import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/dashboard/presentation/widgets/projects_bottom_sheet.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/global_search_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The primary shell page for the application's authenticated interface.
///
/// This widget provides the bottom navigation bar and manages the state of
/// tab navigation using [AppShellBloc]. Module lazy-loading is orchestrated
/// inside the BLoC, keeping this Page a pure presentation concern.
///
/// The app bar is driven by [CurrentProjectNotifier]: when a project is
/// selected it renders [ProjectHeaderAppBar]; otherwise it shows the static
/// app title.
class AppShellPage extends StatefulWidget {
  final AppShellBloc bloc;
  final ProjectUIProvider projectUIProvider;
  final AuthNotifier authNotifier;
  final AuthManager authManager;
  final AppRouter router;

  const AppShellPage({
    super.key,
    required this.bloc,
    required this.projectUIProvider,
    required this.authNotifier,
    required this.authManager,
    required this.router,
  });

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  static final _logger = AppLogger().tag('AppShellPage');
  late final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<String?>? _projectSubscription;
  String? _currentProjectId;

  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    ShellTab.values.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void initState() {
    super.initState();
    _currentProjectNotifier = Modular.get<CurrentProjectNotifier>();
    _currentProjectId = _currentProjectNotifier.currentProjectId;
    _projectSubscription = _currentProjectNotifier.onCurrentProjectChanged
        .listen((id) {
          if (mounted && _currentProjectId != id) {
            setState(() => _currentProjectId = id);
          }
        });
  }

  @override
  void dispose() {
    _projectSubscription?.cancel();
    // Do not close _currentProjectNotifier or widget.bloc — both are DI-owned.
    // Closing a DI-owned BLoC leaves the container holding a closed instance,
    // causing "cannot add events after close" on re-navigation.
    super.dispose();
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    final state = widget.bloc.state;
    final currentNavigator =
        _tabNavigatorKeys[state.selectedTabIndex].currentState;

    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return;
    }

    if (state.selectedTabIndex != 0) {
      widget.bloc.add(const AppShellTabSelected(ShellTab.home));
      return;
    }

    SystemNavigator.pop();
  }

  void _handleTabTap(int index) {
    assert(index < ShellTab.values.length, 'Tab index $index out of range');
    widget.bloc.add(AppShellTabSelected(ShellTab.values[index]));
  }

  Widget _buildTabRoot(ShellTab tab) {
    switch (tab) {
      case ShellTab.home:
        return DashboardPage(
          authNotifier: widget.authNotifier,
          authManager: widget.authManager,
          router: widget.router,
        );
      case ShellTab.calculations:
        return const CalculationsPage();
      case ShellTab.estimation:
        return EstimationModule.landingPage();
      case ShellTab.members:
        return const MembersPage();
    }
  }

  Future<void> _navigateToSearch() async {
    if (!mounted) return;
    try {
      await widget.router.pushNamed(fullGlobalSearchRoute);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to navigate to GlobalSearchPage: $error',
        stackTrace.toString(),
      );
      if (mounted) {
        CoreToast.showError(
          context,
          context.l10n.searchNavigationError,
          context.l10n.closeButton,
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final projectId = _currentProjectId ?? '';
    if (projectId.isEmpty) {
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
            actions: [
              CoreIconWidget(
                icon: CoreIcons.search,
                semanticLabel: context.l10n.dashboardSearchSemanticLabel,
                onTap: () => _navigateToSearch(),
              ),
              const SizedBox(width: CoreSpacing.space4),
            ],
          ),
        ),
      );
    }

    return widget.projectUIProvider.buildProjectHeaderAppbar(
      projectId: projectId,
      onProjectTap: () => ProjectsBottomSheet.show(context),
      onSearchTap: () => _navigateToSearch(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppShellBloc, AppShellState>(
      bloc: widget.bloc,
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
                            key: ValueKey(tab.name),
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
