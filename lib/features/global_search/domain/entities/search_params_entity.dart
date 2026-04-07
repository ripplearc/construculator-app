import 'package:construculator/features/global_search/domain/entities/pagination_params.dart';
import 'package:construculator/features/global_search/domain/entities/search_scope_entity.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing the parameters for a global search operation.
///
/// Mirrors [SearchParamsDto] in the data layer without introducing a data-layer
/// dependency into the domain. The data layer maps this entity to [SearchParamsDto]
/// before passing it to the data source.
///
/// **Date filtering**: [filterByDate] is sent as an ISO8601 string. If the UI
/// lets users pick a calendar date (e.g. March 20th), truncate to start of day
/// (00:00:00) before passing, or ensure the backend RPC treats it as a date range.
class SearchParams extends Equatable {
  /// The search query text.
  final String query;

  /// Optional tag to restrict results to items with this tag.
  final String? filterByTag;

  /// Date filter. Truncate to start of day (00:00:00) if picking a calendar date
  /// to avoid exact-timestamp mismatch with backend.
  final DateTime? filterByDate;

  /// Optional owner identifier to restrict results to items owned by this user.
  final String? filterByOwner;

  /// Optional scope limiting which areas or entity types are searched.
  final SearchScope? scope;

  /// Pagination settings for the search request and result pages.
  final PaginationParams pagination;

  const SearchParams({
    required this.query,
    this.filterByTag,
    this.filterByDate,
    this.filterByOwner,
    this.scope,
    this.pagination = const PaginationParams(),
  });

  static const Object _absent = Object();

  /// Returns a copy of this [SearchParams] with the given fields replaced.
  SearchParams copyWith({
    String? query,
    Object? filterByTag = _absent,
    Object? filterByDate = _absent,
    Object? filterByOwner = _absent,
    Object? scope = _absent,
    PaginationParams? pagination,
  }) {
    return SearchParams(
      query: query ?? this.query,
      filterByTag: filterByTag == _absent ? this.filterByTag : filterByTag as String?,
      filterByDate: filterByDate == _absent ? this.filterByDate : filterByDate as DateTime?,
      filterByOwner: filterByOwner == _absent ? this.filterByOwner : filterByOwner as String?,
      scope: scope == _absent ? this.scope : scope as SearchScope?,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [query, filterByTag, filterByDate, filterByOwner, scope, pagination];
}
