// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserCredential _$UserCredentialFromJson(Map<String, dynamic> json) =>
    _UserCredential(
      id: json['id'] as String,
      email: json['email'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserCredentialToJson(_UserCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'metadata': instance.metadata,
      'created_at': instance.createdAt.toIso8601String(),
    };
