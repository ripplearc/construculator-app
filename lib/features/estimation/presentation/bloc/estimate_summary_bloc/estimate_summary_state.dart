part of 'estimate_summary_bloc.dart';

/// Base class for [EstimateSummaryBloc] states.
sealed class EstimateSummaryState extends Equatable {
  const EstimateSummaryState();
}

/// Before the first load.
class EstimateSummaryInitial extends EstimateSummaryState {
  const EstimateSummaryInitial();

  @override
  List<Object?> get props => [];
}

/// While the estimate is loading.
class EstimateSummaryLoading extends EstimateSummaryState {
  const EstimateSummaryLoading();

  @override
  List<Object?> get props => [];
}

/// The estimate loaded.
class EstimateSummaryLoaded extends EstimateSummaryState {
  const EstimateSummaryLoaded(this.estimate);

  /// The loaded estimate.
  final CostEstimate estimate;

  @override
  List<Object?> get props => [estimate];
}

/// The estimate could not be loaded.
class EstimateSummaryFailure extends EstimateSummaryState {
  const EstimateSummaryFailure(this.failure);

  /// Why the load failed.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
