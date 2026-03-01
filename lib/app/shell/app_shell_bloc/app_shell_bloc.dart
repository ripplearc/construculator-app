import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_shell_event.dart';
part 'app_shell_state.dart';

class AppShellBloc extends Bloc<AppShellEvent, AppShellState> {
  AppShellBloc()
    : super(const AppShellState(selectedTabIndex: 0, loadedTabIndexes: {0})) {
    on<AppShellTabSelected>(_onTabSelected);
  }

  void _onTabSelected(AppShellTabSelected event, Emitter<AppShellState> emit) {
    if (event.index == state.selectedTabIndex) {
      return;
    }

    emit(
      state.copyWith(
        selectedTabIndex: event.index,
        loadedTabIndexes: {...state.loadedTabIndexes, event.index},
      ),
    );
  }
}
