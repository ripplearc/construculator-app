import 'package:flutter/material.dart';

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
