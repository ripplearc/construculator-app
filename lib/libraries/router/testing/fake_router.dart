import 'dart:async';

import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:equatable/equatable.dart';

/// A class to store the route and arguments for a navigation call.
class RouteCall extends Equatable {
  /// The route that was called.
  final String route;

  /// The arguments that were passed to the route.
  final Object? arguments;

  const RouteCall(this.route, this.arguments);

  @override
  List<Object?> get props => [route, arguments];
}

/// A fake implementation of the [AppRouter].
class FakeAppRouter implements AppRouter {
  /// The history of navigation calls.
  final List<RouteCall> navigationHistory = [];

  /// The number of times the pop method was called.
  int popCalls = 0;

  /// When non-null, [pushNamed] throws this exception instead of recording the call.
  Exception? pushError;

  /// When true, [pushNamed] throws after recording the call, letting tests
  /// exercise navigation error handling.
  bool shouldThrowOnPushNamed = false;

  /// When set, [pushNamed] does not complete until this completer does,
  /// letting tests observe in-flight navigation state.
  Completer<void>? pushNamedCompleter;

  @override
  Future<void> pushNamed(String route, {Object? arguments}) async {
    navigationHistory.add(RouteCall(route, arguments));
    final error = pushError;
    if (error != null) throw error;
    if (shouldThrowOnPushNamed) {
      throw Exception('FakeAppRouter: pushNamed failed for $route');
    }
    final completer = pushNamedCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  void pop() {
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
    pushError = null;
    shouldThrowOnPushNamed = false;
    pushNamedCompleter = null;
  }
}
