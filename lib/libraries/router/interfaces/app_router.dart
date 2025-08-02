/// An interface wrapper for the modular router.
abstract class AppRouter {
  /// Used to navigate to a named route.
  /// [route] is the name of the route to navigate to.
  /// [arguments] is the arguments to pass to the route.
  /// eg. ```router.pushNamed('/home', arguments: {'id': 1});```
  /// eg. ```router.pushNamed('/home', arguments: 'johndoe@example.com');```
  Future<void> pushNamed(String route, {Object? arguments});

  /// Used to navigate to a route, clearing the entire stack.
  /// [route] is the route to navigate to.
  /// [arguments] is the arguments to pass to the route.
  /// eg. ```router.navigate('/home', arguments: {'id': 1});```
  /// eg. ```router.navigate('/home', arguments: 'johndoe@example.com');```
  void navigate(String route, {Object? arguments});

  /// Used to pop a route from the navigator.
  /// eg. ```router.pop();```
  void pop();
}
