// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthState {

/// The current authentication status indicating the state of the user.
/// 
/// This can be one of the following values:
/// - [AuthStatus.authenticated]: User is successfully logged in
/// - [AuthStatus.unauthenticated]: User is not logged in
/// - [AuthStatus.connectionError]: Authentication process is in progress
 AuthStatus get status;/// The user credential information if the user is authenticated.
/// 
/// This contains user details such as email, user ID, and other
/// authentication-related information. Will be null when the user
/// is not authenticated or during loading states.
 UserCredential? get user;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);

  /// Serializes this AuthState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,user);

@override
String toString() {
  return 'AuthState(status: $status, user: $user)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 AuthStatus status, UserCredential? user
});


$UserCredentialCopyWith<$Res>? get user;

}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? user = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserCredential?,
  ));
}
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCredentialCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCredentialCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
@JsonSerializable()

class _AuthState extends AuthState {
  const _AuthState({required this.status, this.user}): super._();
  factory _AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);

/// The current authentication status indicating the state of the user.
/// 
/// This can be one of the following values:
/// - [AuthStatus.authenticated]: User is successfully logged in
/// - [AuthStatus.unauthenticated]: User is not logged in
/// - [AuthStatus.connectionError]: Authentication process is in progress
@override final  AuthStatus status;
/// The user credential information if the user is authenticated.
/// 
/// This contains user details such as email, user ID, and other
/// authentication-related information. Will be null when the user
/// is not authenticated or during loading states.
@override final  UserCredential? user;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,user);

@override
String toString() {
  return 'AuthState(status: $status, user: $user)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 AuthStatus status, UserCredential? user
});


@override $UserCredentialCopyWith<$Res>? get user;

}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? user = freezed,}) {
  return _then(_AuthState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as UserCredential?,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCredentialCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $UserCredentialCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
