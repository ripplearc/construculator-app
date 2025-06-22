// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserCredential {

 String get id; String get email; Map<String, dynamic> get metadata; DateTime get createdAt;
/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCredentialCopyWith<UserCredential> get copyWith => _$UserCredentialCopyWithImpl<UserCredential>(this as UserCredential, _$identity);

  /// Serializes this UserCredential to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,const DeepCollectionEquality().hash(metadata),createdAt);

@override
String toString() {
  return 'UserCredential(id: $id, email: $email, metadata: $metadata, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $UserCredentialCopyWith<$Res>  {
  factory $UserCredentialCopyWith(UserCredential value, $Res Function(UserCredential) _then) = _$UserCredentialCopyWithImpl;
@useResult
$Res call({
 String id, String email, Map<String, dynamic> metadata, DateTime createdAt
});




}
/// @nodoc
class _$UserCredentialCopyWithImpl<$Res>
    implements $UserCredentialCopyWith<$Res> {
  _$UserCredentialCopyWithImpl(this._self, this._then);

  final UserCredential _self;
  final $Res Function(UserCredential) _then;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? email = null,Object? metadata = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _UserCredential extends UserCredential {
  const _UserCredential({required this.id, required this.email, required final  Map<String, dynamic> metadata, required this.createdAt}): _metadata = metadata,super._();
  factory _UserCredential.fromJson(Map<String, dynamic> json) => _$UserCredentialFromJson(json);

@override final  String id;
@override final  String email;
 final  Map<String, dynamic> _metadata;
@override Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  DateTime createdAt;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCredentialCopyWith<_UserCredential> get copyWith => __$UserCredentialCopyWithImpl<_UserCredential>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserCredentialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserCredential&&(identical(other.id, id) || other.id == id)&&(identical(other.email, email) || other.email == email)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,email,const DeepCollectionEquality().hash(_metadata),createdAt);

@override
String toString() {
  return 'UserCredential(id: $id, email: $email, metadata: $metadata, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$UserCredentialCopyWith<$Res> implements $UserCredentialCopyWith<$Res> {
  factory _$UserCredentialCopyWith(_UserCredential value, $Res Function(_UserCredential) _then) = __$UserCredentialCopyWithImpl;
@override @useResult
$Res call({
 String id, String email, Map<String, dynamic> metadata, DateTime createdAt
});




}
/// @nodoc
class __$UserCredentialCopyWithImpl<$Res>
    implements _$UserCredentialCopyWith<$Res> {
  __$UserCredentialCopyWithImpl(this._self, this._then);

  final _UserCredential _self;
  final $Res Function(_UserCredential) _then;

/// Create a copy of UserCredential
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? email = null,Object? metadata = null,Object? createdAt = null,}) {
  return _then(_UserCredential(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
