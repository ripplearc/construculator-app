part of 'app_shell_bloc.dart';

/// Represents the state of the app shell, including the currently selected tab
/// and the set of tabs that have been loaded.
class AppShellState extends Equatable {
  /// The index of the currently active tab.
  final int selectedTabIndex;

  /// The set of indices of all tabs that have been loaded.
  final Set<int> loadedTabIndexes;

  /// Whether the Calculator entry point should be reachable, driven by the
  /// `calculator-enabled` PostHog feature flag. Defaults to `false` (fails
  /// closed) until the flag has resolved.
  final bool calculatorEnabled;

  const AppShellState({
    required this.selectedTabIndex,
    required this.loadedTabIndexes,
    this.calculatorEnabled = false,
  });

  AppShellState copyWith({
    int? selectedTabIndex,
    Set<int>? loadedTabIndexes,
    bool? calculatorEnabled,
  }) {
    return AppShellState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      loadedTabIndexes: loadedTabIndexes ?? this.loadedTabIndexes,
      calculatorEnabled: calculatorEnabled ?? this.calculatorEnabled,
    );
  }

  @override
  List<Object?> get props => [
    selectedTabIndex,
    loadedTabIndexes,
    calculatorEnabled,
  ];
}
