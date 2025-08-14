// coverage:ignore-file
import 'package:freezed_annotation/freezed_annotation.dart';

part 'professional_role.freezed.dart';
part 'professional_role.g.dart';

/// This is the domain entity for a professional role with a unique identifier and name.
@freezed
sealed class ProfessionalRole with _$ProfessionalRole {
  /// The unique identifier for the professional role.
  const factory ProfessionalRole({
    required String id,
    required String name,
  }) = _ProfessionalRole;

  factory ProfessionalRole.fromJson(Map<String, dynamic> json) =>
      _$ProfessionalRoleFromJson(json);
} 