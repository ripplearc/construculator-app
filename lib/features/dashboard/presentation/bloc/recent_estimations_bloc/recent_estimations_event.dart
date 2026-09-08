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

/// Signals that the project load failed, so no selection is ever going to
/// arrive and the loading hold must resolve to an error instead of
/// waiting forever. Dispatched by the shell when the project dropdown
/// load reaches its failure state (CA-900).
class RecentEstimationsProjectLoadFailed extends RecentEstimationsEvent {
  /// Creates a [RecentEstimationsProjectLoadFailed] event.
  const RecentEstimationsProjectLoadFailed();
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
