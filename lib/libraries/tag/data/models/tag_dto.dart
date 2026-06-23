import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/tag/domain/entities/tag_entity.dart';
import 'package:equatable/equatable.dart';

/// Data transfer object for a tag row in the `tags` table.
class TagDto extends Equatable {
  /// Unique identifier of the tag.
  final String id;

  /// Human-readable tag name.
  final String name;

  /// Creates a [TagDto].
  const TagDto({required this.id, required this.name});

  /// Creates a [TagDto] from a Supabase row.
  factory TagDto.fromJson(Map<String, dynamic> json) {
    return TagDto(
      id: json[DatabaseConstants.idColumn] as String,
      name: json[DatabaseConstants.nameColumn] as String,
    );
  }

  /// Maps this DTO to its domain entity.
  Tag toDomain() => Tag(id: id, name: name);

  @override
  List<Object?> get props => [id, name];
}
