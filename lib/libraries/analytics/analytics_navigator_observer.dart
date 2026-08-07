import 'dart:async';

import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Tracks screen views by observing Modular's navigation stack.
///
/// Registered via `Modular.routerDelegate.setObservers([...])` — there is no
/// `navigatorObservers` param on `MaterialApp.router` to hook into directly.
///
/// Only ever sends the route name (sanitized to strip resolved path-param
/// values, e.g. `/details/abc123` becomes `/details/:estimationId`). Never
/// sends `RouteSettings.arguments`, which may carry free text or PII.
///
/// Routes through [AnalyticsRepository.track], not [PosthogWrapper] directly
/// — this is what makes it respect the single enable/disable gate for free,
/// since a disabled app resolves to `NoOpAnalyticsRepository` at bootstrap.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  /// Creates an [AnalyticsNavigatorObserver] backed by [analyticsRepository].
  ///
  /// [argsProvider] defaults to the live `Modular.args` and only exists as a
  /// seam for tests to control resolved route params deterministically.
  AnalyticsNavigatorObserver({
    required AnalyticsRepository analyticsRepository,
    ModularArguments Function()? argsProvider,
  }) : _analyticsRepository = analyticsRepository,
       _argsProvider = argsProvider ?? (() => Modular.args);

  final AnalyticsRepository _analyticsRepository;
  final ModularArguments Function() _argsProvider;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _trackScreenView(route.settings.name);
  }

  void _trackScreenView(String? rawName) {
    if (rawName == null || rawName.isEmpty) return;
    final screenName = _sanitize(rawName);
    unawaited(
      _analyticsRepository.track(
        AnalyticsEvent(
          name: 'screen_viewed',
          properties: {'screen_name': screenName},
        ),
      ),
    );
  }

  String _sanitize(String name) {
    var sanitized = name;
    for (final entry in _argsProvider().params.entries) {
      final value = entry.value?.toString();
      if (value != null && value.isNotEmpty) {
        sanitized = sanitized.replaceAll(value, ':${entry.key}');
      }
    }
    return sanitized;
  }
}
