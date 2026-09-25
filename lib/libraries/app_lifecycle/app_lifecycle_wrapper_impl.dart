import 'dart:async';

import 'package:construculator/libraries/app_lifecycle/interfaces/app_lifecycle_wrapper.dart';
import 'package:flutter/widgets.dart';

/// [AppLifecycleWrapper] backed by Flutter's [AppLifecycleListener].
///
/// Create it once the Flutter binding is initialized. The app keeps one for
/// its whole run; [dispose] releases it.
class AppLifecycleWrapperImpl implements AppLifecycleWrapper {
  late final AppLifecycleListener _listener;
  final _foregroundChanges = StreamController<bool>.broadcast();
  bool _isInForeground = _isForegroundState(
    WidgetsBinding.instance.lifecycleState,
  );

  AppLifecycleWrapperImpl() {
    _listener = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  bool get isInForeground => _isInForeground;

  @override
  Stream<bool> get foregroundChanges => _foregroundChanges.stream;

  /// Stops listening to the app lifecycle and closes [foregroundChanges].
  void dispose() {
    _listener.dispose();
    unawaited(_foregroundChanges.close());
  }

  void _onStateChange(AppLifecycleState state) {
    final isInForeground = _isForegroundState(state);
    if (isInForeground == _isInForeground) return;
    _isInForeground = isInForeground;
    _foregroundChanges.add(isInForeground);
  }

  // Inactive still counts as foreground: the app stays visible and has only
  // lost focus for a moment, to an incoming call or the app switcher. A null
  // state means the platform has not reported one yet, as at launch.
  static bool _isForegroundState(AppLifecycleState? state) =>
      state == null ||
      state == AppLifecycleState.resumed ||
      state == AppLifecycleState.inactive;
}
