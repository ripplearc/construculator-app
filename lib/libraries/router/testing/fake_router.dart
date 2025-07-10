import 'package:construculator/libraries/router/interfaces/app_router.dart';

// This class is used to store the route and arguments for a navigation call.
class RouteCall {
  /// The route that was called.
  final String route;

  /// The arguments that were passed to the route.
  final Object? arguments;

  RouteCall(this.route, this.arguments);
}

/// This is a fake implementation of the app router.
class FakeAppRouter implements AppRouter {
  /// The history of navigation calls.
  final List<RouteCall> navigationHistory = [];

  /// The number of times the pop method was called.
  int popCalls = 0;

  @override
  Future<void> pushNamed(String route, {Object? arguments}) async {
    navigationHistory.add(RouteCall(route, arguments));
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCalls++;
  }

  @override
  void navigate(String route, {Object? arguments}) {
    navigationHistory.clear();
    navigationHistory.add(RouteCall(route, arguments));
  }

  /// Resets the router.
  void reset() {
    navigationHistory.clear();
    popCalls = 0;
  }
}
