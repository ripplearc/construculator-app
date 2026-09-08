import 'package:equatable/equatable.dart';

/// Domain entity representing a tag used for search and filtering.
///
/// Tags are reference data managed by the backend; clients only read them.
class Tag extends Equatable {
  /// Unique identifier of the tag.
  final String id;

  /// Human-readable tag name shown in filter UIs.
  final String name;

  /// Creates a [Tag].
  const Tag({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}
