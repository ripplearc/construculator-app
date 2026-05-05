part of 'recent_estimations_bloc.dart';

abstract class RecentEstimationsEvent extends Equatable {
  const RecentEstimationsEvent();

  @override
  List<Object?> get props => [];
}

class RecentEstimationsWatchStarted extends RecentEstimationsEvent {
  const RecentEstimationsWatchStarted();
}

class _RecentEstimationsProjectChanged extends RecentEstimationsEvent {
  const _RecentEstimationsProjectChanged();
}

class _RecentEstimationsUpdated extends RecentEstimationsEvent {
  final Either<Failure, List<CostEstimate>> result;
  const _RecentEstimationsUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
