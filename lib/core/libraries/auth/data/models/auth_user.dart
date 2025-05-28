import 'package:construculator_app_architecture/core/libraries/auth/data/types/auth_types.dart';

class User {
  final String id;
  final String credentialId;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final String professionalRole;
  final String? profilePhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfileStatus userStatus;
  final Map<String, dynamic> userPreferences;

  User({
    required this.id,
    required this.credentialId,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.professionalRole,
    this.profilePhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.userStatus,
    required this.userPreferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      credentialId: json['credential_id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      professionalRole: json['professional_role'] as String,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userStatus: json['user_status'] == 'active' ? UserProfileStatus.active : UserProfileStatus.inactive ,
      userPreferences: json['user_preferences'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credential_id': credentialId,
      'email': email,
      'phone': phone,
      'first_name': firstName,
      'last_name': lastName,
      'professional_role': professionalRole,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_status': userStatus.toString().split('.').last,
      'user_preferences': userPreferences,
    };
  }

  static User empty() {
    return User(
      id: '',
      credentialId: '',
      email: '',
      phone: '',
      firstName: '',
      lastName: '',
      professionalRole: '',
      profilePhotoUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userStatus: UserProfileStatus.inactive,
      userPreferences: {},
    );
  }

  // Helper to get full name
  String get fullName => '$firstName $lastName';
  
  // Copy with method for creating modified instances
  User copyWith({
    String? id,
    String? credentialId,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    String? professionalRole,
    String? profilePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserProfileStatus? userStatus,
    Map<String, dynamic>? userPreferences,
  }) {
    return User(
      id: id ?? this.id,
      credentialId: credentialId ?? this.credentialId,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      professionalRole: professionalRole ?? this.professionalRole,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userStatus: userStatus ?? this.userStatus,
      userPreferences: userPreferences ?? this.userPreferences,
    );
  }
}