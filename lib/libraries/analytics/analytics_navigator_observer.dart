import 'dart:async';

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
  AnalyticsNavigatorObserver({required this._analyticsRepository});

  final AnalyticsRepository _analyticsRepository;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final settings = route.settings;
    final templateName = settings is ModularPage
        ? settings.route.name
        : settings.name;
    _trackScreenView(templateName);
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
