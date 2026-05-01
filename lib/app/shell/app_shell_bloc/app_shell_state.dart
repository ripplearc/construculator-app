part of 'app_shell_bloc.dart';

/// Represents the state of the app shell, including the currently selected tab
/// and the set of tabs that have been loaded.
class AppShellState extends Equatable {
  /// The index of the currently active tab.
  final int selectedTabIndex;

  /// The set of indices of all tabs that have been loaded.
  final Set<int> loadedTabIndexes;

  const AppShellState({
    required this.selectedTabIndex,
    required this.loadedTabIndexes,
  });

  /// Creates a copy of this state, replacing the provided properties with new values.
  AppShellState copyWith({int? selectedTabIndex, Set<int>? loadedTabIndexes}) {
    return AppShellState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      loadedTabIndexes: loadedTabIndexes ?? this.loadedTabIndexes,
    );
  }

  @override
  List<Object> get props => [selectedTabIndex, loadedTabIndexes];
}
