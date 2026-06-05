import 'dart:async';

import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_shell_event.dart';
part 'app_shell_state.dart';

/// BLoC responsible for managing tab selection, lazy-load state, and the
/// currently active project in the app shell.
///
/// Owns the side effect of lazily loading feature modules via [TabModuleManager]
/// so that the Page layer remains a pure presentation concern.
class AppShellBloc extends Bloc<AppShellEvent, AppShellState> {
  final TabModuleManager _moduleLoader;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<String?>? _projectSubscription;

  AppShellBloc({
    required TabModuleManager moduleLoader,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _moduleLoader = moduleLoader,
       _currentProjectNotifier = currentProjectNotifier,
       super(
         AppShellState(
           selectedTabIndex: 0,
           loadedTabIndexes: const {},
           currentProjectId: currentProjectNotifier.currentProjectId,
         ),
       ) {
    on<AppShellInitialized>(_onInitialized);
    on<AppShellTabSelected>(_onTabSelected);
    on<_AppShellCurrentProjectChanged>(_onCurrentProjectChanged);
    _projectSubscription = _currentProjectNotifier.onCurrentProjectChanged
        .listen((id) => add(_AppShellCurrentProjectChanged(id)));
    add(const AppShellInitialized());
  }

  Future<void> _onInitialized(
    AppShellInitialized event,
    Emitter<AppShellState> emit,
  ) async {
    await _moduleLoader.ensureTabModuleLoaded(ShellTab.home);
    emit(state.copyWith(loadedTabIndexes: {0}, selectedTabIndex: 0));
  }

  Future<void> _onTabSelected(
    AppShellTabSelected event,
    Emitter<AppShellState> emit,
  ) async {
    final tabIndex = event.tab.index;
    if (tabIndex == state.selectedTabIndex) return;

    await _moduleLoader.ensureTabModuleLoaded(event.tab);

    emit(
      state.copyWith(
        selectedTabIndex: tabIndex,
        loadedTabIndexes: {...state.loadedTabIndexes, tabIndex},
      ),
    );
  }

  void _onCurrentProjectChanged(
    _AppShellCurrentProjectChanged event,
    Emitter<AppShellState> emit,
  ) {
    if (event.projectId == state.currentProjectId) return;
    emit(state.copyWith(currentProjectId: event.projectId));
  }

  @override
  Future<void> close() {
    _projectSubscription?.cancel();
    return super.close();
  }
}
