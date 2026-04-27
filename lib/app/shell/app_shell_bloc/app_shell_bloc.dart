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
      super(const AppShellState(selectedTabIndex: 0, loadedTabIndexes: {0})) {
    on<AppShellTabSelected>(_onTabSelected);
  }

  Future<void> _onTabSelected(
    AppShellTabSelected event,
    Emitter<AppShellState> emit,
  ) async {
    if (event.index == state.selectedTabIndex) return;

    final tab = ShellTab.values[event.index];
    await _moduleLoader.ensureTabModuleLoaded(tab);

    emit(
      state.copyWith(
        selectedTabIndex: event.index,
        loadedTabIndexes: {...state.loadedTabIndexes, event.index},
      ),
    );
  }
}
