import 'package:construculator/app/shell/app_shell_bloc/app_shell_bloc.dart';
import 'package:construculator/app/shell/module_model.dart';
import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:construculator/features/calculations/presentation/pages/calculations_page.dart';
import 'package:construculator/features/dashboard/presentation/bloc/recent_estimations_bloc/recent_estimations_bloc.dart';
import 'package:construculator/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:construculator/features/estimation/estimation_module.dart';
import 'package:construculator/features/members/presentation/pages/members_page.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/auth/interfaces/auth_notifier.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The primary shell page for the application's authenticated interface.
///
/// This widget provides the bottom navigation bar and manages the state of
/// tab navigation using [AppShellBloc]. Module lazy-loading is orchestrated
/// inside the BLoC, keeping this Page a pure presentation concern.
class AppShellPage extends StatefulWidget {
  final AppShellBloc appShellBloc;
  final ProjectUIProvider projectUIProvider;

  // TODO: [CA-708] Remove once DashboardPage reads these from the module directly.
  // https://ripplearc.youtrack.cloud/issue/CA-708
  final AuthNotifier authNotifier;
  final AuthManager authManager;
  final AppRouter router;
  final RecentEstimationsBloc recentEstimationsBloc;

  const AppShellPage({
    super.key,
    required this.appShellBloc,
    required this.projectUIProvider,
    required this.authNotifier,
    required this.authManager,
    required this.router,
    required this.recentEstimationsBloc,
  });

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    ShellTab.values.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void dispose() {
    widget.appShellBloc.close();
    super.dispose();
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    final state = widget.appShellBloc.state;
    final currentNavigator =
        _tabNavigatorKeys[state.selectedTabIndex].currentState;

    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return;
    }

    if (state.selectedTabIndex != 0) {
      widget.appShellBloc.add(const AppShellTabSelected(ShellTab.home));
      return;
    }

    SystemNavigator.pop();
  }

  void _handleTabTap(int index) {
    assert(index < ShellTab.values.length, 'Tab index $index out of range');
    widget.appShellBloc.add(AppShellTabSelected(ShellTab.values[index]));
  }

  Widget _buildTabRoot(ShellTab tab) {
    switch (tab) {
      // TODO: [CA-708] Remove once DashboardPage reads these from the module directly.
      // https://ripplearc.youtrack.cloud/issue/CA-708
      case ShellTab.home:
        return DashboardPage(
          authNotifier: widget.authNotifier,
          authManager: widget.authManager,
          router: widget.router,
          recentEstimationsBloc: widget.recentEstimationsBloc,
          appShellBloc: widget.appShellBloc,
        );
      case ShellTab.calculations:
        return const CalculationsPage();
      case ShellTab.estimation:
        return EstimationModule.landingPage();
      case ShellTab.members:
        return const MembersPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppShellBloc, AppShellState>(
      bloc: widget.appShellBloc,
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
          child: Scaffold(
            appBar: widget.projectUIProvider.buildProjectHeaderAppbar(),
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
