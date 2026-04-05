part of 'app_shell_bloc.dart';

/// Represents the current state of the application shell, including tracking
/// which tab is currently active and which tabs have already had their modules loaded.
class AppShellState extends Equatable {
  /// The index of the currently selected tab in the bottom navigation bar.
  final int selectedTabIndex;

  /// A set of tab indexes that have already been loaded by the [TabModuleManager].
  final Set<int> loadedTabIndexes;

  const AppShellState({
    required this.selectedTabIndex,
    required this.loadedTabIndexes,
  });

  /// Creates a copy of this state with the given fields replaced with new values.
  AppShellState copyWith({int? selectedTabIndex, Set<int>? loadedTabIndexes}) {
    return AppShellState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      loadedTabIndexes: loadedTabIndexes ?? this.loadedTabIndexes,
    );
  }

  @override
  List<Object> get props => [selectedTabIndex, loadedTabIndexes];
}
