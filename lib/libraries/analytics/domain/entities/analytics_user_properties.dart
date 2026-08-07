import 'package:equatable/equatable.dart';

/// Person properties set on the current user via `identify()` or
/// `setUserProperties()`.
class AnalyticsUserProperties extends Equatable {
  /// Creates [AnalyticsUserProperties].
  const AnalyticsUserProperties({
    this.email,
    this.name,
    this.role,
    this.custom = const {},
  });

  /// The user's email address.
  final String? email;

  /// The user's display name.
  final String? name;

  /// The user's role.
  final String? role;

  /// Additional properties not covered by the named fields above.
  final Map<String, dynamic> custom;

  /// Flattens the named fields and [custom] into a single map, omitting
  /// unset named fields.
  Map<String, dynamic> toMap() => {
    if (email != null) 'email': email,
    if (name != null) 'name': name,
    if (role != null) 'role': role,
    ...custom,
  };

  @override
  List<Object?> get props => [email, name, role, custom];
}
