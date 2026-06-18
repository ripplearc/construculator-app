import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_shell_event.dart';
part 'app_shell_state.dart';

/// BLoC responsible for managing tab selection and lazy-load state in the app shell.
///
/// Owns the side effect of lazily loading feature modules via [TabModuleManager]
/// so that the Page layer remains a pure presentation concern.
class AppShellBloc extends Bloc<AppShellEvent, AppShellState> {
  final TabModuleManager _moduleLoader;

  AppShellBloc({required TabModuleManager moduleLoader})
    : _moduleLoader = moduleLoader,
      super(
        const AppShellState(selectedTabIndex: 0, loadedTabIndexes: {}),
      ) {
    on<AppShellInitialized>(_onInitialized);
    on<AppShellTabSelected>(_onTabSelected);
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

}
