part of 'recent_estimations_bloc.dart';

/// Base event for [RecentEstimationsBloc].
abstract class RecentEstimationsEvent extends Equatable {
  /// Defines a constant constructor for recent estimations event.
  const RecentEstimationsEvent();

  @override
  List<Object?> get props => [];
}

/// Starts (or restarts) the recent estimations stream.
class RecentEstimationsWatchStarted extends RecentEstimationsEvent {
  /// Defines a constructor to start watching recent estimations.
  const RecentEstimationsWatchStarted();
}

class _RecentEstimationsUpdated extends RecentEstimationsEvent {
  final Either<Failure, List<CostEstimate>> result;
  const _RecentEstimationsUpdated(this.result);

  @override
  List<Object?> get props => [result];
}
