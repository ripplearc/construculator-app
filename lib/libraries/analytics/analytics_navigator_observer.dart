import 'dart:async';

import 'package:construculator/libraries/analytics/current_screen_tracker.dart';
import 'package:construculator/libraries/analytics/domain/entities/analytics_event.dart';
import 'package:construculator/libraries/analytics/domain/repositories/analytics_repository.dart';
import 'package:flutter/widgets.dart';
// ModularPage is not re-exported from the public flutter_modular.dart
// barrel, even though flutter_modular's own RouterOutlet relies on casting
// route.settings to it internally — this mirrors that same pattern.
// ignore: implementation_imports
import 'package:flutter_modular/src/presenter/navigation/modular_page.dart';

/// Tracks screen views by observing Modular's navigation stack.
///
/// Registered via `Modular.routerDelegate.setObservers([...])` — there is no
/// `navigatorObservers` param on `MaterialApp.router` to hook into directly.
///
/// Only ever sends the route's originally-declared template name (e.g.
/// `/details/:estimationId`), read from `ModularPage.route.name` — never the
/// resolved `.uri` or `RouteSettings.arguments`, which may carry a real ID,
/// free text, or PII.
///
/// Routes through [AnalyticsRepository.track], not [PosthogWrapper] directly
/// — this is what makes it respect the single enable/disable gate for free,
/// since a disabled app resolves to `NoOpAnalyticsRepository` at bootstrap.
class AnalyticsNavigatorObserver extends NavigatorObserver {
  /// Creates an [AnalyticsNavigatorObserver] backed by [analyticsRepository].
  ///
  /// [currentScreenTracker] must be the same instance given to
  /// `AnalyticsRepositoryImpl` so every tracked event, not just
  /// `screen_viewed`, carries the currently active screen.
  AnalyticsNavigatorObserver({
    required this._analyticsRepository,
    required this._currentScreenTracker,
  });

  final AnalyticsRepository _analyticsRepository;
  final CurrentScreenTracker _currentScreenTracker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final templateName = _templateNameOf(route);
    _syncScreenName(templateName);
    _trackScreenView(templateName);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _syncScreenName(_templateNameOf(previousRoute));
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (previousRoute != null) {
      _syncScreenName(_templateNameOf(previousRoute));
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _syncScreenName(_templateNameOf(newRoute));
    }
  }

  String? _templateNameOf(Route<dynamic> route) {
    final settings = route.settings;
    return settings is ModularPage ? settings.route.name : settings.name;
  }

  void _syncScreenName(String? templateName) {
    if (templateName != null && templateName.isNotEmpty) {
      _currentScreenTracker.screenName = templateName;
    }
  }

  void _trackScreenView(String? screenName) {
    if (screenName == null || screenName.isEmpty) return;
    unawaited(
      _analyticsRepository.track(
        AnalyticsEvent(
          name: 'screen_viewed',
          properties: {'screen_name': screenName},
        ),
      ),
    );
  }
}
