part of 'cost_items_bloc.dart';

/// Base class for [CostItemsBloc] states.
sealed class CostItemsState extends Equatable {
  const CostItemsState();
}

/// Before the first load.
class CostItemsInitial extends CostItemsState {
  const CostItemsInitial();

  @override
  List<Object?> get props => [];
}

/// While the first load of an estimate runs.
class CostItemsLoading extends CostItemsState {
  const CostItemsLoading();

  @override
  List<Object?> get props => [];
}

/// The cost lines loaded.
class CostItemsLoaded extends CostItemsState {
  const CostItemsLoaded({
    required this.items,
    required this.materialsSubtotal,
    required this.laborSubtotal,
    required this.equipmentSubtotal,
  });

  /// Every cost line of the estimate, oldest first.
  final List<CostItem> items;

  /// The sum of the Materials lines, in dollars.
  final double materialsSubtotal;

  /// The sum of the Labor lines, in dollars.
  final double laborSubtotal;

  /// The sum of the Equipment lines, in dollars.
  final double equipmentSubtotal;

  /// The Materials lines, in the order of [items].
  List<CostItem> get materialLines => _linesOf(CostItemType.material);

  /// The Labor lines, in the order of [items].
  List<CostItem> get laborLines => _linesOf(CostItemType.labor);

  /// The Equipment lines, in the order of [items].
  List<CostItem> get equipmentLines => _linesOf(CostItemType.equipment);

  List<CostItem> _linesOf(CostItemType type) =>
      items.where((item) => item.itemType == type).toList();

  @override
  List<Object?> get props => [
    items,
    materialsSubtotal,
    laborSubtotal,
    equipmentSubtotal,
  ];
}

/// The cost lines could not be loaded.
class CostItemsFailure extends CostItemsState {
  const CostItemsFailure(this.failure, {this.failedLoads = 1});

  /// Why the load failed.
  final Failure failure;

  /// How many loads in a row have failed, counting this one. It starts again
  /// from one after a load works.
  final int failedLoads;

  @override
  List<Object?> get props => [failure, failedLoads];
}
