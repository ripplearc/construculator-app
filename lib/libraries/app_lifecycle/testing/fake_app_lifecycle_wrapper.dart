import 'dart:async';

import 'package:construculator/libraries/app_lifecycle/interfaces/app_lifecycle_wrapper.dart';

/// [AppLifecycleWrapper] that a test moves between foreground and background.
///
/// Starts in the foreground. Changes are delivered synchronously, so a test
/// sees their effect without pumping.
class FakeAppLifecycleWrapper implements AppLifecycleWrapper {
  final _foregroundChanges = StreamController<bool>.broadcast(sync: true);
  bool _isInForeground = true;

  @override
  bool get isInForeground => _isInForeground;

  @override
  Stream<bool> get foregroundChanges => _foregroundChanges.stream;

  /// Moves the app to the foreground or the background.
  void setInForeground(bool isInForeground) {
    if (isInForeground == _isInForeground) return;
    _isInForeground = isInForeground;
    _foregroundChanges.add(isInForeground);
  }

  /// Returns to the foreground, for use between tests.
  void reset() => setInForeground(true);
}
