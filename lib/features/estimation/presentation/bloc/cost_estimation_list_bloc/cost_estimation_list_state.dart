// coverage:ignore-file

part of 'cost_estimation_list_bloc.dart';

/// Abstract class for cost estimation list states.
abstract class CostEstimationListState extends Equatable {
  const CostEstimationListState();
}

/// Initial state when the bloc is first created
class CostEstimationListInitial extends CostEstimationListState {
  const CostEstimationListInitial();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimations are being loaded
class CostEstimationListLoading extends CostEstimationListState {
  const CostEstimationListLoading();

  @override
  List<Object?> get props => [];
}

/// State when the cost estimations are loaded successfully but the list is empty
class CostEstimationListEmpty extends CostEstimationListState {
  const CostEstimationListEmpty();

  @override
  List<Object?> get props => [];
}

/// Abstract base class for states that can contain cost estimation data.
abstract class CostEstimationListWithData extends CostEstimationListState {
  final UnmodifiableListView<CostEstimate> estimates;

  final bool hasMore;

  final bool isLoadingMore;

  CostEstimationListWithData({
    required List<CostEstimate> estimates,
    this.hasMore = true,
    this.isLoadingMore = false,
  }) : estimates = UnmodifiableListView<CostEstimate>(
         List<CostEstimate>.from(estimates),
       );

  /// List of properties that will be used to compare states
  @override
  List<Object?> get props => [estimates, hasMore, isLoadingMore];
}

/// State when loading cost estimations fails but we have previous data
class CostEstimationListError extends CostEstimationListWithData {
  /// The error message describing what went wrong
  final Failure failure;

  CostEstimationListError({
    required this.failure,
    required super.estimates,
    super.hasMore,
    super.isLoadingMore,
  });

  @override
  List<Object?> get props => [failure, estimates, hasMore, isLoadingMore];
}

/// State when the cost estimations are loaded successfully with data
class CostEstimationListLoaded extends CostEstimationListWithData {
  CostEstimationListLoaded({
    required super.estimates,
    super.hasMore,
    super.isLoadingMore,
  });

  CostEstimationListLoaded copyWith({
    List<CostEstimate>? estimates,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CostEstimationListLoaded(
      estimates: estimates ?? this.estimates.toList(),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [estimates, hasMore, isLoadingMore];
}
