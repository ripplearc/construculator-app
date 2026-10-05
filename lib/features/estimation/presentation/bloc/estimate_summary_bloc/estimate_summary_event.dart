part of 'estimate_summary_bloc.dart';

/// Base class for [EstimateSummaryBloc] events.
sealed class EstimateSummaryEvent extends Equatable {
  const EstimateSummaryEvent();
}

/// Fired to load, or reload, the estimate.
class EstimateSummaryRequested extends EstimateSummaryEvent {
  const EstimateSummaryRequested(this.estimateId);

  /// The estimate to load.
  final String estimateId;

  @override
  List<Object?> get props => [estimateId];
}
