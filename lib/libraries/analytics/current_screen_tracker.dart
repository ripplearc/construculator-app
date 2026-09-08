/// Shared, mutable holder of the currently active screen's sanitized
/// template name (e.g. `/details/:estimationId`).
///
/// [AnalyticsNavigatorObserver] updates [screenName] on every navigation;
/// [AnalyticsRepositoryImpl] reads it to attach `screen_name` to every
/// tracked event, not just navigation events. A single instance must be
/// shared between both — see `AppBootstrap.currentScreenTracker`.
class CurrentScreenTracker {
  /// The sanitized template name of the currently active screen, or `null`
  /// before the first navigation.
  String? screenName;
}
