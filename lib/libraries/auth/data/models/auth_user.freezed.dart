// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$User {

 String get id; String get credentialId; String get email; String? get phone; String? get countryCode; String get firstName; String get lastName; String get professionalRole; String? get profilePhotoUrl; DateTime get createdAt; DateTime get updatedAt; UserProfileStatus get userStatus; Map<String, dynamic> get userPreferences;
/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserCopyWith<User> get copyWith => _$UserCopyWithImpl<User>(this as User, _$identity);

  /// Serializes this User to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is User&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.professionalRole, professionalRole) || other.professionalRole == professionalRole)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userStatus, userStatus) || other.userStatus == userStatus)&&const DeepCollectionEquality().equals(other.userPreferences, userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,email,phone,countryCode,firstName,lastName,professionalRole,profilePhotoUrl,createdAt,updatedAt,userStatus,const DeepCollectionEquality().hash(userPreferences));

@override
String toString() {
  return 'User(id: $id, credentialId: $credentialId, email: $email, phone: $phone, countryCode: $countryCode, firstName: $firstName, lastName: $lastName, professionalRole: $professionalRole, profilePhotoUrl: $profilePhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, userStatus: $userStatus, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class $UserCopyWith<$Res>  {
  factory $UserCopyWith(User value, $Res Function(User) _then) = _$UserCopyWithImpl;
@useResult
$Res call({
 String id, String credentialId, String email, String? phone, String? countryCode, String firstName, String lastName, String professionalRole, String? profilePhotoUrl, DateTime createdAt, DateTime updatedAt, UserProfileStatus userStatus, Map<String, dynamic> userPreferences
});




}
/// @nodoc
class _$UserCopyWithImpl<$Res>
    implements $UserCopyWith<$Res> {
  _$UserCopyWithImpl(this._self, this._then);

  final User _self;
  final $Res Function(User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? credentialId = null,Object? email = null,Object? phone = freezed,Object? countryCode = freezed,Object? firstName = null,Object? lastName = null,Object? professionalRole = null,Object? profilePhotoUrl = freezed,Object? createdAt = null,Object? updatedAt = null,Object? userStatus = null,Object? userPreferences = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,professionalRole: null == professionalRole ? _self.professionalRole : professionalRole // ignore: cast_nullable_to_non_nullable
as String,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userStatus: null == userStatus ? _self.userStatus : userStatus // ignore: cast_nullable_to_non_nullable
as UserProfileStatus,userPreferences: null == userPreferences ? _self.userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _User extends User {
  const _User({required this.id, required this.credentialId, required this.email, this.phone, this.countryCode, required this.firstName, required this.lastName, required this.professionalRole, this.profilePhotoUrl, required this.createdAt, required this.updatedAt, required this.userStatus, required final  Map<String, dynamic> userPreferences}): _userPreferences = userPreferences,super._();
  factory _User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

@override final  String id;
@override final  String credentialId;
@override final  String email;
@override final  String? phone;
@override final  String? countryCode;
@override final  String firstName;
@override final  String lastName;
@override final  String professionalRole;
@override final  String? profilePhotoUrl;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  UserProfileStatus userStatus;
 final  Map<String, dynamic> _userPreferences;
@override Map<String, dynamic> get userPreferences {
  if (_userPreferences is EqualUnmodifiableMapView) return _userPreferences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_userPreferences);
}


/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserCopyWith<_User> get copyWith => __$UserCopyWithImpl<_User>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _User&&(identical(other.id, id) || other.id == id)&&(identical(other.credentialId, credentialId) || other.credentialId == credentialId)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.countryCode, countryCode) || other.countryCode == countryCode)&&(identical(other.firstName, firstName) || other.firstName == firstName)&&(identical(other.lastName, lastName) || other.lastName == lastName)&&(identical(other.professionalRole, professionalRole) || other.professionalRole == professionalRole)&&(identical(other.profilePhotoUrl, profilePhotoUrl) || other.profilePhotoUrl == profilePhotoUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.userStatus, userStatus) || other.userStatus == userStatus)&&const DeepCollectionEquality().equals(other._userPreferences, _userPreferences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,credentialId,email,phone,countryCode,firstName,lastName,professionalRole,profilePhotoUrl,createdAt,updatedAt,userStatus,const DeepCollectionEquality().hash(_userPreferences));

@override
String toString() {
  return 'User(id: $id, credentialId: $credentialId, email: $email, phone: $phone, countryCode: $countryCode, firstName: $firstName, lastName: $lastName, professionalRole: $professionalRole, profilePhotoUrl: $profilePhotoUrl, createdAt: $createdAt, updatedAt: $updatedAt, userStatus: $userStatus, userPreferences: $userPreferences)';
}


}

/// @nodoc
abstract mixin class _$UserCopyWith<$Res> implements $UserCopyWith<$Res> {
  factory _$UserCopyWith(_User value, $Res Function(_User) _then) = __$UserCopyWithImpl;
@override @useResult
$Res call({
 String id, String credentialId, String email, String? phone, String? countryCode, String firstName, String lastName, String professionalRole, String? profilePhotoUrl, DateTime createdAt, DateTime updatedAt, UserProfileStatus userStatus, Map<String, dynamic> userPreferences
});




}
/// @nodoc
class __$UserCopyWithImpl<$Res>
    implements _$UserCopyWith<$Res> {
  __$UserCopyWithImpl(this._self, this._then);

  final _User _self;
  final $Res Function(_User) _then;

/// Create a copy of User
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? credentialId = null,Object? email = null,Object? phone = freezed,Object? countryCode = freezed,Object? firstName = null,Object? lastName = null,Object? professionalRole = null,Object? profilePhotoUrl = freezed,Object? createdAt = null,Object? updatedAt = null,Object? userStatus = null,Object? userPreferences = null,}) {
  return _then(_User(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,credentialId: null == credentialId ? _self.credentialId : credentialId // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,countryCode: freezed == countryCode ? _self.countryCode : countryCode // ignore: cast_nullable_to_non_nullable
as String?,firstName: null == firstName ? _self.firstName : firstName // ignore: cast_nullable_to_non_nullable
as String,lastName: null == lastName ? _self.lastName : lastName // ignore: cast_nullable_to_non_nullable
as String,professionalRole: null == professionalRole ? _self.professionalRole : professionalRole // ignore: cast_nullable_to_non_nullable
as String,profilePhotoUrl: freezed == profilePhotoUrl ? _self.profilePhotoUrl : profilePhotoUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,userStatus: null == userStatus ? _self.userStatus : userStatus // ignore: cast_nullable_to_non_nullable
as UserProfileStatus,userPreferences: null == userPreferences ? _self._userPreferences : userPreferences // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
