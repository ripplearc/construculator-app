import 'package:construculator/libraries/analytics/domain/utils/unmodifiable_map_view.dart';
import 'package:equatable/equatable.dart';

/// Person properties set on the current user via `identify()` or
/// `setUserProperties()`.
class AnalyticsUserProperties extends Equatable {
  /// Creates [AnalyticsUserProperties].
  const AnalyticsUserProperties({
    this.email,
    this.name,
    this.role,
    Map<String, dynamic> custom = const {},
    // ignore: prefer_initializing_formals
  }) : _custom = custom;

  /// The user's email address.
  final String? email;

  /// The user's display name.
  final String? name;

  /// The user's role.
  final String? role;

  final Map<String, dynamic> _custom;

  /// Additional properties not covered by the named fields above.
  Map<String, dynamic> get custom => _custom.unmodifiableView;

  /// Flattens the named fields and [custom] into a single map, omitting
  /// unset named fields.
  Map<String, dynamic> toMap() => {
    if (email != null) 'email': email,
    if (name != null) 'name': name,
    if (role != null) 'role': role,
    ..._custom,
  };

  @override
  List<Object?> get props => [email, name, role, _custom];
}
