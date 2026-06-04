import 'package:construculator/app/shell/tab_module_manager.dart';
import 'package:construculator/features/dashboard/presentation/bloc/project_dropdown_bloc/project_dropdown_bloc.dart';
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
  final ProjectDropdownBloc Function() _projectDropdownBlocFactory;

  /// Creates an [AppShellBloc].
  ///
  /// [moduleLoader] orchestrates lazy loading of feature modules per tab.
  /// [projectDropdownBlocFactory] is called after the home module loads to
  /// seed [CurrentProjectNotifier] before the app bar renders.
  AppShellBloc({
    required TabModuleManager moduleLoader,
    required ProjectDropdownBloc Function() projectDropdownBlocFactory,
  }) : _moduleLoader = moduleLoader,
       _projectDropdownBlocFactory = projectDropdownBlocFactory,
       super(const AppShellState(selectedTabIndex: 0, loadedTabIndexes: {})) {
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
    _projectDropdownBlocFactory().add(const ProjectDropdownStarted());
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
