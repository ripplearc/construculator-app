part of 'recent_estimations_bloc.dart';

/// Base state for the recent estimations stream.
abstract class RecentEstimationsState extends Equatable {
  /// Defines a constant constructor for recent estimations state.
  const RecentEstimationsState();

  @override
  List<Object?> get props => [];
}

/// The initial and re-loading state. Carries [lastKnownEstimations]
/// so the UI can continue showing stale data while reloading.
class RecentEstimationsLoading extends RecentEstimationsState {
  /// The list of estimations.
  final List<CostEstimate>? lastKnownEstimations;

  /// Defines a constructor taking [lastKnownEstimations].
  const RecentEstimationsLoading({this.lastKnownEstimations});

  @override
  List<Object?> get props => [lastKnownEstimations];
}

/// Emitted when the stream delivers a successful list of estimations.
class RecentEstimationsLoaded extends RecentEstimationsState {
  /// The list of loaded estimations.
  final List<CostEstimate> estimations;

  /// Defines a constructor taking [estimations].
  const RecentEstimationsLoaded(this.estimations);

  @override
  List<Object?> get props => [estimations];
}

/// Emitted when the stream delivers a failure.
class RecentEstimationsError extends RecentEstimationsState {
  /// The error message.
  final String message;

  /// Defines a constructor taking [message].
  const RecentEstimationsError(this.message);

  @override
  List<Object?> get props => [message];
}
