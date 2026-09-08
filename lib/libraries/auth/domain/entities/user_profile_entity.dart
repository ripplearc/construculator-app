import 'package:equatable/equatable.dart';

/// Represents a simplified user profile for activity logs and user display.
///
/// This entity maps to the `user_profiles` database view which contains
/// essential user information. While initially created for activity log display,
/// it includes display-oriented helpers (`initials`, `fullName`) that make it
/// suitable for general user representation across the application.
///
/// **Design Note**: This entity lives in the auth library as it represents
/// authenticated user data from the `user_profiles` view, which is part of the
/// authentication/user management domain. The display helpers are conveniences
/// that don't change the core domain concept.
class UserProfile extends Equatable {
  /// Unique identifier for the user
  final String id;

  /// User's first name
  final String firstName;

  /// User's last name
  final String lastName;

  /// User's professional role
  final String professionalRole;

  /// URL to the user's profile photo
  final String? profilePhotoUrl;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.professionalRole,
    this.profilePhotoUrl,
  });

  /// Returns the full name of the user
  String get fullName => '$firstName $lastName';

  /// Returns the initials of the user (e.g., "John Doe" -> "JD")
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$firstInitial$lastInitial';
  }

  /// Creates a copy of this UserProfile with the given fields replaced
  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? professionalRole,
    String? profilePhotoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      professionalRole: professionalRole ?? this.professionalRole,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    professionalRole,
    profilePhotoUrl,
  ];
}
