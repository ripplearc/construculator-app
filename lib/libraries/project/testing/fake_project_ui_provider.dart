import 'package:construculator/libraries/project/presentation/project_ui_provider.dart';
import 'package:flutter/material.dart';

/// Fake implementation of [ProjectUIProvider] for testing.
///
/// Returns a lightweight [FakeProjectAppBar] instead of the real
/// `ProjectHeaderAppBar`, so shell tests can verify that the project app bar
/// slot is populated without pulling in the project header's bloc and
/// notifier dependencies.
class FakeProjectUIProvider implements ProjectUIProvider {
  /// Number of times [buildProjectHeaderAppbar] was invoked, so tests can
  /// assert the shell actually requested the app bar from the provider.
  int buildProjectHeaderAppbarCallCount = 0;

  /// Clears recorded calls; invoke from `tearDown` when the fake is reused
  /// across tests.
  void reset() {
    buildProjectHeaderAppbarCallCount = 0;
  }

  @override
  PreferredSizeWidget buildProjectHeaderAppbar({
    VoidCallback? onProjectTap,
    VoidCallback? onSearchTap,
    VoidCallback? onNotificationTap,
  }) {
    buildProjectHeaderAppbarCallCount++;
    return const PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: FakeProjectAppBar(),
    );
  }
}

/// Placeholder app bar rendered by [FakeProjectUIProvider].
///
/// Public so tests can locate it with `find.byType(FakeProjectAppBar)` to
/// assert the provider-built app bar is shown.
class FakeProjectAppBar extends StatelessWidget {
  /// Creates a placeholder app bar that renders nothing.
  const FakeProjectAppBar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
