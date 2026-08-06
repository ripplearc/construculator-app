import 'package:equatable/equatable.dart';

/// A single trackable analytics event.
class AnalyticsEvent extends Equatable {
  /// Creates an [AnalyticsEvent] with the given [name] and optional [properties].
  const AnalyticsEvent({required this.name, this.properties = const {}});

  /// The event name, e.g. `estimation_created`. Use `snake_case`.
  final String name;

  /// Event properties sent alongside the event.
  ///
  /// Must never contain PII or sensitive values — use user properties via
  /// `identify()` for user-level data instead.
  final Map<String, dynamic> properties;

  @override
  List<Object?> get props => [name, properties];
}
