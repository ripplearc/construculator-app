// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
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
  userStatus: $enumDecode(_$UserProfileStatusEnumMap, json['user_status']),
  userPreferences: json['user_preferences'] as Map<String, dynamic>,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'credential_id': instance.credentialId,
  'email': instance.email,
  'phone': instance.phone,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'professional_role': instance.professionalRole,
  'profile_photo_url': instance.profilePhotoUrl,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'user_status': _$UserProfileStatusEnumMap[instance.userStatus]!,
  'user_preferences': instance.userPreferences,
};

const _$UserProfileStatusEnumMap = {
  UserProfileStatus.active: 'active',
  UserProfileStatus.inactive: 'inactive',
};
