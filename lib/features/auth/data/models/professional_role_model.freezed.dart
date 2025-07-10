// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'professional_role_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfessionalRoleModel {

 String get id; String get name;
/// Create a copy of ProfessionalRoleModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfessionalRoleModelCopyWith<ProfessionalRoleModel> get copyWith => _$ProfessionalRoleModelCopyWithImpl<ProfessionalRoleModel>(this as ProfessionalRoleModel, _$identity);

  /// Serializes this ProfessionalRoleModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfessionalRoleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProfessionalRoleModel(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ProfessionalRoleModelCopyWith<$Res>  {
  factory $ProfessionalRoleModelCopyWith(ProfessionalRoleModel value, $Res Function(ProfessionalRoleModel) _then) = _$ProfessionalRoleModelCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class _$ProfessionalRoleModelCopyWithImpl<$Res>
    implements $ProfessionalRoleModelCopyWith<$Res> {
  _$ProfessionalRoleModelCopyWithImpl(this._self, this._then);

  final ProfessionalRoleModel _self;
  final $Res Function(ProfessionalRoleModel) _then;

/// Create a copy of ProfessionalRoleModel
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

class _ProfessionalRoleModel extends ProfessionalRoleModel {
  const _ProfessionalRoleModel({required this.id, required this.name}): super._();
  factory _ProfessionalRoleModel.fromJson(Map<String, dynamic> json) => _$ProfessionalRoleModelFromJson(json);

@override final  String id;
@override final  String name;

/// Create a copy of ProfessionalRoleModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfessionalRoleModelCopyWith<_ProfessionalRoleModel> get copyWith => __$ProfessionalRoleModelCopyWithImpl<_ProfessionalRoleModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfessionalRoleModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfessionalRoleModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ProfessionalRoleModel(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ProfessionalRoleModelCopyWith<$Res> implements $ProfessionalRoleModelCopyWith<$Res> {
  factory _$ProfessionalRoleModelCopyWith(_ProfessionalRoleModel value, $Res Function(_ProfessionalRoleModel) _then) = __$ProfessionalRoleModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$ProfessionalRoleModelCopyWithImpl<$Res>
    implements _$ProfessionalRoleModelCopyWith<$Res> {
  __$ProfessionalRoleModelCopyWithImpl(this._self, this._then);

  final _ProfessionalRoleModel _self;
  final $Res Function(_ProfessionalRoleModel) _then;

/// Create a copy of ProfessionalRoleModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ProfessionalRoleModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
