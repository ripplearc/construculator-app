import 'package:construculator/features/global_search/data/models/pagination_params.dart';
import 'package:construculator/features/global_search/data/models/search_scope.dart';
import 'package:equatable/equatable.dart';

/// Parameters for global search API calls.
///
/// Used as input for the [global_search] RPC function.
///
/// **Date filtering**: [filterByDate] is sent as an ISO8601 string. If the UI
/// lets users pick a calendar date (e.g. March 20th), truncate to start of day
/// (00:00:00) before passing, or ensure the backend RPC treats it as a date range.
class SearchParams extends Equatable {
  final String query;
  final String? filterByTag;

  /// Date filter. Truncate to start of day (00:00:00) if picking a calendar date
  /// to avoid exact-timestamp mismatch with backend.
  final DateTime? filterByDate;
  final String? filterByOwner;
  final SearchScope? scope;
  final PaginationParams pagination;

  const SearchParams({
    required this.query,
    this.filterByTag,
    this.filterByDate,
    this.filterByOwner,
    this.scope,
    this.pagination = const PaginationParams(),
  });

  SearchParams copyWith({
    String? query,
    String? filterByTag,
    DateTime? filterByDate,
    String? filterByOwner,
    SearchScope? scope,
    PaginationParams? pagination,
  }) {
    return SearchParams(
      query: query ?? this.query,
      filterByTag: filterByTag ?? this.filterByTag,
      filterByDate: filterByDate ?? this.filterByDate,
      filterByOwner: filterByOwner ?? this.filterByOwner,
      scope: scope ?? this.scope,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [query, filterByTag, filterByDate, filterByOwner, scope, pagination];
}
