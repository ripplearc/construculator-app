import 'package:flutter/material.dart';

/// A navigator widget designed for tab-based navigation patterns.
///
/// **Two-Tier Navigation Architecture:**
/// * **Tier 1 (Root):** For pages that should appear above the entire shell 
///   (e.g., details pages), use `Modular.to.pushNamed()`. These push onto 
///   the root Navigator and hide the tab bar.
/// * **Tier 2 (In-Tab):** For drill-downs within a specific tab where the 
///   tab bar must stay visible, push onto this [TabNavigator]'s local 
///   Navigator using `Navigator.of(context).push()`. NEVER use `Modular.to` 
///   for Tier 2 flows.
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
