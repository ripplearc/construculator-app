part of 'app_shell_bloc.dart';

/// Represents the state of the app shell, including the currently selected tab
/// and the set of tabs that have been loaded.
class AppShellState extends Equatable {
  /// The index of the currently active tab.
  final int selectedTabIndex;

  /// The set of indices of all tabs that have been loaded.
  final Set<int> loadedTabIndexes;

  /// The ID of the currently selected project, or `null` if none is active.
  final String? currentProjectId;

  const AppShellState({
    required this.selectedTabIndex,
    required this.loadedTabIndexes,
    this.currentProjectId,
  });

  static const Object _absent = Object();

  /// Creates a copy of this state, replacing the provided properties with new values.
  ///
  /// Pass [currentProjectId] explicitly to update or clear the project ID;
  /// omit it to keep the existing value.
  AppShellState copyWith({
    int? selectedTabIndex,
    Set<int>? loadedTabIndexes,
    Object? currentProjectId = _absent,
  }) {
    return AppShellState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      loadedTabIndexes: loadedTabIndexes ?? this.loadedTabIndexes,
      currentProjectId: identical(currentProjectId, _absent)
          ? this.currentProjectId
          : currentProjectId as String?,
    );
  }

  @override
  List<Object?> get props => [selectedTabIndex, loadedTabIndexes, currentProjectId];
}
