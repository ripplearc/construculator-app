part of 'cost_items_bloc.dart';

/// Base class for [CostItemsBloc] events.
sealed class CostItemsEvent extends Equatable {
  const CostItemsEvent();
}

/// Fired to load the cost lines of an estimate.
class CostItemsRequested extends CostItemsEvent {
  const CostItemsRequested(this.estimateId);

  /// The estimate to load the cost lines of.
  final String estimateId;

  @override
  List<Object?> get props => [estimateId];
}

/// Fired to reload the estimate last requested, for example after a line is
/// added. Ignored until an estimate has been requested.
class CostItemsRefreshed extends CostItemsEvent {
  const CostItemsRefreshed();

  @override
  List<Object?> get props => [];
}
