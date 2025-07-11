/// This is the interface for the app router.
abstract class AppRouter {
  /// Pushes a [route] to the navigator.
  /// Accepts a route and an optional [arguments] as parameters.
  ///
  /// Returns a [Future] that emits an [void].
  Future<void> pushNamed(String route, {Object? arguments});

  /// Sets the provided [route] as the root and replaces all, does not close bloc
  /// Accepts a route and an optional [arguments] as parameters.
  // void pushNamedRemoveAll(String route, {Object? arguments});

    /// Sets the provided [route] as the root and replaces all, closes bloc
  /// Accepts a route and an optional [arguments] as parameters.
  void navigate(String route, {Object? arguments});

  /// Pops a route from the navigator.
  /// Accepts an optional result as a parameter.
  ///
  /// Returns an [void].
  void pop<T extends Object?>([T? result]);
}
