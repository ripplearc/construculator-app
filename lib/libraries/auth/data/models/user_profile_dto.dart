import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for UserProfile entity.
///
/// This DTO represents the serialized form of a user profile as it appears
/// in the database `user_profiles` view. It handles the conversion between
/// the database JSON format and the domain entity structure.
class UserProfileDto extends Equatable {
  /// Unique identifier for the user.
  final String id;

  /// The credential ID associated with the user.
  final String? credentialId;

  /// User's first name.
  final String firstName;

  /// User's last name.
  final String lastName;

  /// User's professional role.
  final String professionalRole;

  /// URL to the user's profile photo.
  final String? profilePhotoUrl;

  const UserProfileDto({
    required this.id,
    this.credentialId,
    required this.firstName,
    required this.lastName,
    required this.professionalRole,
    this.profilePhotoUrl,
  });

  /// Creates a [UserProfileDto] from a JSON map.
  ///
  /// This factory method handles the conversion from the database JSON format
  /// to the DTO structure, mapping snake_case JSON keys to camelCase Dart properties.
  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      id: json[DatabaseConstants.idColumn] as String,
      credentialId: json[DatabaseConstants.credentialIdColumn] as String?,
      firstName: json[DatabaseConstants.firstNameColumn] as String,
      lastName: json[DatabaseConstants.lastNameColumn] as String,
      professionalRole: json[DatabaseConstants.professionalRoleColumn] as String,
      profilePhotoUrl: json[DatabaseConstants.profilePhotoUrlColumn] as String?,
    );
  }

  /// Converts this DTO to a JSON map.
  ///
  /// This method converts the DTO back to the database JSON format,
  /// mapping camelCase Dart properties to snake_case JSON keys.
  ///
  /// **Note**: This method serializes null optional fields explicitly
  /// (e.g., `'credential_id': null`). It is intended for read/display
  /// serialization only
  Map<String, dynamic> toJson() => {
    DatabaseConstants.idColumn: id,
    DatabaseConstants.credentialIdColumn: credentialId,
    DatabaseConstants.firstNameColumn: firstName,
    DatabaseConstants.lastNameColumn: lastName,
    DatabaseConstants.professionalRoleColumn: professionalRole,
    DatabaseConstants.profilePhotoUrlColumn: profilePhotoUrl,
  };

  /// Converts this DTO to a domain [UserProfile] entity.
  UserProfile toDomain() {
    return UserProfile(
      id: id,
      credentialId: credentialId,
      firstName: firstName,
      lastName: lastName,
      professionalRole: professionalRole,
      profilePhotoUrl: profilePhotoUrl,
    );
  }

  /// Creates a [UserProfileDto] from a domain [UserProfile] entity.
  factory UserProfileDto.fromDomain(UserProfile userProfile) {
    return UserProfileDto(
      id: userProfile.id,
      credentialId: userProfile.credentialId,
      firstName: userProfile.firstName,
      lastName: userProfile.lastName,
      professionalRole: userProfile.professionalRole,
      profilePhotoUrl: userProfile.profilePhotoUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    credentialId,
    firstName,
    lastName,
    professionalRole,
    profilePhotoUrl,
  ];
}
