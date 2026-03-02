import 'package:flutter/material.dart';

/// A navigator widget designed for tab-based navigation patterns.
///
/// Each [TabNavigator] maintains its own navigation stack, allowing
/// independent back-navigation within tabs. Use [navigatorKey] to
/// access the navigator state for programmatic navigation control.
class TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final WidgetBuilder rootBuilder;

  const TabNavigator({
    super.key,
    required this.navigatorKey,
    required this.rootBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          builder: rootBuilder,
          settings: settings,
        );
      },
    );
  }
}
