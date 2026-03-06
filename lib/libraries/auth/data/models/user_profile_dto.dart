import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
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
      id: json['id'] as String,
      credentialId: json['credential_id'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      professionalRole: json['professional_role'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  /// Converts this DTO to a JSON map.
  ///
  /// This method converts the DTO back to the database JSON format,
  /// mapping camelCase Dart properties to snake_case JSON keys.
  Map<String, dynamic> toJson() => {
    'id': id,
    'credential_id': credentialId,
    'first_name': firstName,
    'last_name': lastName,
    'professional_role': professionalRole,
    'profile_photo_url': profilePhotoUrl,
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
