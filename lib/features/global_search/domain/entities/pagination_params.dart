import 'package:equatable/equatable.dart';

/// Domain value object encapsulating offset/limit pagination for a search operation.
///
/// - [offset] is the number of records to skip (default: 0).
/// - [limit] is the maximum number of records to return per page (default: 20).
///
/// Example — fetching the second page of 20 results:
/// ```dart
/// const PaginationParams(offset: 20, limit: 20)
/// ```
class PaginationParams extends Equatable {
  final int offset;
  final int limit;

  const PaginationParams({
    this.offset = 0,
    this.limit = 20,
  });

  PaginationParams copyWith({int? offset, int? limit}) {
    return PaginationParams(
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [offset, limit];
}
