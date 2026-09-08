part of 'app_shell_bloc.dart';

/// Represents the state of the app shell, including the currently selected tab
/// and the set of tabs that have been loaded.
class AppShellState extends Equatable {
  /// The currently active tab.
  final ShellTab selectedTab;

  /// The set of all tabs that have been loaded.
  final Set<ShellTab> loadedTabs;

  /// Whether the Calculator entry point should be reachable, driven by the
  /// `calculator-enabled` PostHog feature flag. Defaults to `false` (fails
  /// closed) until the flag has resolved.
  final bool calculatorEnabled;

  const AppShellState({
    required this.selectedTab,
    required this.loadedTabs,
    this.calculatorEnabled = false,
  });

  AppShellState copyWith({
    ShellTab? selectedTab,
    Set<ShellTab>? loadedTabs,
    bool? calculatorEnabled,
  }) {
    return AppShellState(
      selectedTab: selectedTab ?? this.selectedTab,
      loadedTabs: loadedTabs ?? this.loadedTabs,
      calculatorEnabled: calculatorEnabled ?? this.calculatorEnabled,
    );
  }

  @override
  List<Object?> get props => [
    selectedTab,
    loadedTabs,
    calculatorEnabled,
  ];
}
