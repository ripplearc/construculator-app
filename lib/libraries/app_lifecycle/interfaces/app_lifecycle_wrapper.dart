/// Tells whether the app is in the foreground, and when that changes.
///
/// Wraps Flutter's app lifecycle so code outside the widget tree, such as a
/// repository, can stop counting time while the contractor is in another app.
/// Tests drive it by hand with `FakeAppLifecycleWrapper`.
abstract class AppLifecycleWrapper {
  /// Whether the app is on screen now.
  bool get isInForeground;

  /// Emits the new value of [isInForeground] each time it changes.
  Stream<bool> get foregroundChanges;
}
