// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'professional_role.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfessionalRole {

 String get id; String get name;
/// Create a copy of ProfessionalRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfessionalRoleCopyWith<ProfessionalRole> get copyWith => _$ProfessionalRoleCopyWithImpl<ProfessionalRole>(this as ProfessionalRole, _$identity);

  /// Serializes this ProfessionalRole to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfessionalRole&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProfessionalRole(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ProfessionalRoleCopyWith<$Res>  {
  factory $ProfessionalRoleCopyWith(ProfessionalRole value, $Res Function(ProfessionalRole) _then) = _$ProfessionalRoleCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$ProfessionalRoleCopyWithImpl<$Res>
    implements $ProfessionalRoleCopyWith<$Res> {
  _$ProfessionalRoleCopyWithImpl(this._self, this._then);

  final ProfessionalRole _self;
  final $Res Function(ProfessionalRole) _then;

/// Create a copy of ProfessionalRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// @nodoc
@JsonSerializable()

class _ProfessionalRole implements ProfessionalRole {
  const _ProfessionalRole({required this.id, required this.name});
  factory _ProfessionalRole.fromJson(Map<String, dynamic> json) => _$ProfessionalRoleFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of ProfessionalRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfessionalRoleCopyWith<_ProfessionalRole> get copyWith => __$ProfessionalRoleCopyWithImpl<_ProfessionalRole>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfessionalRoleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfessionalRole&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProfessionalRole(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ProfessionalRoleCopyWith<$Res> implements $ProfessionalRoleCopyWith<$Res> {
  factory _$ProfessionalRoleCopyWith(_ProfessionalRole value, $Res Function(_ProfessionalRole) _then) = __$ProfessionalRoleCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$ProfessionalRoleCopyWithImpl<$Res>
    implements _$ProfessionalRoleCopyWith<$Res> {
  __$ProfessionalRoleCopyWithImpl(this._self, this._then);

  final _ProfessionalRole _self;
  final $Res Function(_ProfessionalRole) _then;

/// Create a copy of ProfessionalRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ProfessionalRole(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
