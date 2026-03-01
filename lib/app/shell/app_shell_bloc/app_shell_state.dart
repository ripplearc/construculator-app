part of 'app_shell_bloc.dart';

class AppShellState extends Equatable {
  final int selectedTabIndex;
  final Set<int> loadedTabIndexes;

  const AppShellState({
    required this.selectedTabIndex,
    required this.loadedTabIndexes,
  });

  AppShellState copyWith({int? selectedTabIndex, Set<int>? loadedTabIndexes}) {
    return AppShellState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      loadedTabIndexes: loadedTabIndexes ?? this.loadedTabIndexes,
    );
  }

  @override
  List<Object> get props => [selectedTabIndex, loadedTabIndexes];
}
