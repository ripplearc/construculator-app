import 'package:construculator/features/global_search/domain/entities/pagination_params.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing the parameters for a global search operation.
///
/// Mirrors [SearchParamsDto] in the data layer without introducing a data-layer
/// dependency into the domain. The data layer maps this entity to [SearchParamsDto]
/// before passing it to the data source.
///
/// **Date filtering**: [filterByDateFrom]/[filterByDateTo] are sent as ISO8601
/// strings and define an inclusive range. Either bound may be omitted for an
/// open-ended range.
class SearchParams extends Equatable {
  /// The search query text.
  final String query;

  /// Optional tag to restrict results to items with this tag.
  final String? filterByTag;

  /// Inclusive lower bound of the modification-date range filter.
  final DateTime? filterByDateFrom;

  /// Inclusive upper bound of the modification-date range filter.
  final DateTime? filterByDateTo;

  /// Optional owner identifier to restrict results to items owned by this user.
  final String? filterByOwner;

  /// Optional scope limiting which areas or entity types are searched.
  final SearchScope? scope;

  /// Pagination settings for the search request and result pages.
  final PaginationParams pagination;

  const SearchParams({
    required this.query,
    this.filterByTag,
    this.filterByDateFrom,
    this.filterByDateTo,
    this.filterByOwner,
    this.scope,
    this.pagination = const PaginationParams(),
  });

  static const Object _absent = Object();

  /// Returns a copy of this [SearchParams] with the given fields replaced.
  SearchParams copyWith({
    String? query,
    Object? filterByTag = _absent,
    Object? filterByDateFrom = _absent,
    Object? filterByDateTo = _absent,
    Object? filterByOwner = _absent,
    Object? scope = _absent,
    PaginationParams? pagination,
  }) {
    return SearchParams(
      query: query ?? this.query,
      filterByTag: filterByTag == _absent ? this.filterByTag : filterByTag as String?,
      filterByDateFrom: filterByDateFrom == _absent ? this.filterByDateFrom : filterByDateFrom as DateTime?,
      filterByDateTo: filterByDateTo == _absent ? this.filterByDateTo : filterByDateTo as DateTime?,
      filterByOwner: filterByOwner == _absent ? this.filterByOwner : filterByOwner as String?,
      scope: scope == _absent ? this.scope : scope as SearchScope?,
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
