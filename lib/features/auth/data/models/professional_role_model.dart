// coverage:ignore-file
import 'package:construculator/features/auth/domain/entities/professional_role.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'professional_role_model.freezed.dart';
part 'professional_role_model.g.dart';

/// Defines the structure for a professional role with a unique identifier and name.
@freezed
sealed class ProfessionalRoleModel with _$ProfessionalRoleModel {
  const ProfessionalRoleModel._();

  /// Creates a new [ProfessionalRoleModel] instance
  ///
  /// - [id]: The unique identifier for the professional role
  /// - [name]: The name of the professional role
  const factory ProfessionalRoleModel({
    required String id,
    required String name,
  }) = _ProfessionalRoleModel;

  factory ProfessionalRoleModel.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalRoleModelFromJson(json);

  ProfessionalRole toEntity() => ProfessionalRole(id: id, name: name);
} 