import 'package:construculator/features/global_search/data/models/pagination_params_dto.dart';
import 'package:construculator/libraries/global_search/data/search_scope_dto.dart';
import 'package:equatable/equatable.dart';

/// Parameters for global search API calls.
///
/// Used as input for the [global_search] RPC function.
///
/// **Date filtering**: [filterByDateFrom]/[filterByDateTo] are sent as ISO8601
/// strings and define an inclusive range. Either bound may be omitted for an
/// open-ended range.
class SearchParamsDto extends Equatable {
  final String query;
  final String? filterByTag;

  /// Inclusive lower bound of the modification-date range filter.
  final DateTime? filterByDateFrom;

  /// Inclusive upper bound of the modification-date range filter.
  final DateTime? filterByDateTo;
  final String? filterByOwner;
  final SearchScopeDto? scope;
  final PaginationParamsDto pagination;

  const SearchParamsDto({
    required this.query,
    this.filterByTag,
    this.filterByDateFrom,
    this.filterByDateTo,
    this.filterByOwner,
    this.scope,
    this.pagination = const PaginationParamsDto(),
  });

  static const Object _absent = Object();

  SearchParamsDto copyWith({
    String? query,
    Object? filterByTag = _absent,
    Object? filterByDateFrom = _absent,
    Object? filterByDateTo = _absent,
    Object? filterByOwner = _absent,
    Object? scope = _absent,
    PaginationParamsDto? pagination,
  }) {
    return SearchParamsDto(
      query: query ?? this.query,
      filterByTag: filterByTag == _absent ? this.filterByTag : filterByTag as String?,
      filterByDateFrom: filterByDateFrom == _absent ? this.filterByDateFrom : filterByDateFrom as DateTime?,
      filterByDateTo: filterByDateTo == _absent ? this.filterByDateTo : filterByDateTo as DateTime?,
      filterByOwner: filterByOwner == _absent ? this.filterByOwner : filterByOwner as String?,
      scope: scope == _absent ? this.scope : scope as SearchScopeDto?,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [
    query,
    filterByTag,
    filterByDateFrom,
    filterByDateTo,
    filterByOwner,
    scope,
    pagination,
  ];
}
