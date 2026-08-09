import 'package:construculator/libraries/analytics/domain/utils/unmodifiable_map_view.dart';
import 'package:equatable/equatable.dart';

/// A single trackable analytics event.
class AnalyticsEvent extends Equatable {
  /// Creates an [AnalyticsEvent] with the given [name] and optional [properties].
  const AnalyticsEvent({
    required this.name,
    Map<String, dynamic> properties = const {},
  }) : _properties = properties;

  /// The event name, e.g. `estimation_created`. Use `snake_case`.
  final String name;

  final Map<String, dynamic> _properties;

  /// Event properties sent alongside the event.
  ///
  /// Must never contain PII or sensitive values — use user properties via
  /// `identify()` for user-level data instead.
  Map<String, dynamic> get properties => _properties.unmodifiableView;

  @override
  List<Object?> get props => [name, _properties];
}
