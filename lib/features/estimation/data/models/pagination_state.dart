import 'package:equatable/equatable.dart';

/// Tracks pagination state for a specific project's estimation list.
class PaginationState extends Equatable {
  /// Current offset for the next page fetch
  final int currentOffset;

  /// Number of items per page
  final int pageSize;

  /// Whether there are more items to fetch
  final bool hasMore;

  /// Whether a page fetch is currently in progress
  final bool isLoadingMore;

  const PaginationState({
    this.currentOffset = 0,
    this.pageSize = 10,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  PaginationState copyWith({
    int? currentOffset,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return PaginationState(
      currentOffset: currentOffset ?? this.currentOffset,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [currentOffset, pageSize, hasMore, isLoadingMore];
}
