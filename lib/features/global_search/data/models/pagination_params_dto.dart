import 'package:equatable/equatable.dart';

/// Encapsulates offset/limit pagination for API requests.
///
/// Used as a value object within [SearchParamsDto] to control which page of
/// results is returned by the `global_search` RPC.
///
/// - [offset] is the number of records to skip (default: 0).
/// - [limit] is the maximum number of records to return per page (default: 20).
///
/// Example — fetching the second page of 20 results:
/// ```dart
/// const PaginationParamsDto(offset: 20, limit: 20)
/// ```
class PaginationParamsDto extends Equatable {
  final int offset;
  final int limit;

  const PaginationParamsDto({
    this.offset = 0,
    this.limit = 20,
  });

  PaginationParamsDto copyWith({int? offset, int? limit}) {
    return PaginationParamsDto(
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [offset, limit];
}
