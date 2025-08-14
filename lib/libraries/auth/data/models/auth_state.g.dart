// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthState _$AuthStateFromJson(Map<String, dynamic> json) => _AuthState(
  status: $enumDecode(_$AuthStatusEnumMap, json['status']),
  user: json['user'] == null
      ? null
      : UserCredential.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthStateToJson(_AuthState instance) =>
    <String, dynamic>{
      'status': _$AuthStatusEnumMap[instance.status]!,
      'user': instance.user,
    };

const _$AuthStatusEnumMap = {
  AuthStatus.authenticated: 'authenticated',
  AuthStatus.unauthenticated: 'unauthenticated',
  AuthStatus.connectionError: 'connectionError',
};
