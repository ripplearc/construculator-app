part of 'recent_estimations_bloc.dart';

abstract class RecentEstimationsState extends Equatable {
  const RecentEstimationsState();

  @override
  List<Object?> get props => [];
}

class RecentEstimationsLoading extends RecentEstimationsState {
  final List<CostEstimate>? lastKnownEstimations;

  const RecentEstimationsLoading({this.lastKnownEstimations});

  @override
  List<Object?> get props => [lastKnownEstimations];
}

class RecentEstimationsLoaded extends RecentEstimationsState {
  final List<CostEstimate> estimations;
  const RecentEstimationsLoaded(this.estimations);

  @override
  List<Object?> get props => [estimations];
}

class RecentEstimationsError extends RecentEstimationsState {
  final String message;
  const RecentEstimationsError(this.message);

  @override
  List<Object?> get props => [message];
}
