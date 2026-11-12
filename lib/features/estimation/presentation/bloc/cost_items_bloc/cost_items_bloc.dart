import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'cost_items_event.dart';
part 'cost_items_state.dart';

/// Loads the cost lines of one estimate and adds up a subtotal for each of
/// Materials, Labor and Equipment, so the screen never adds up lines.
///
/// A subtotal is the sum of each line's `itemTotalCost`, added in whole cents.
///
/// A refresh does not emit loading, so the lines stay on screen until the
/// reload finishes. A reload that fails replaces them with
/// [CostItemsFailure].
class CostItemsBloc extends Bloc<CostItemsEvent, CostItemsState> {
  final CostItemRepository _repository;
  String? _estimateId;
  int _failedLoads = 0;

  CostItemsBloc({required this._repository}) : super(const CostItemsInitial()) {
    on<CostItemsEvent>(
      _onEvent,
      transformer: (events, mapper) => events.switchMap(mapper),
    );
  }

  Future<void> _onEvent(
    CostItemsEvent event,
    Emitter<CostItemsState> emit,
  ) async {
    final String estimateId;
    switch (event) {
      case CostItemsRequested():
        estimateId = event.estimateId;
        _estimateId = estimateId;
        _failedLoads = 0;
        emit(const CostItemsLoading());
      case CostItemsRefreshed():
        final loadedEstimateId = _estimateId;
        if (loadedEstimateId == null) return;
        estimateId = loadedEstimateId;
    }
    final result = await _repository.getCostItemsForEstimate(estimateId);
    result.fold(
      (failure) => emit(CostItemsFailure(failure, failedLoads: ++_failedLoads)),
      (items) {
        _failedLoads = 0;
        emit(
          CostItemsLoaded(
            items: items,
            materialsSubtotal: _subtotalOf(items, CostItemType.material),
            laborSubtotal: _subtotalOf(items, CostItemType.labor),
            equipmentSubtotal: _subtotalOf(items, CostItemType.equipment),
          ),
        );
      },
    );
  }

  double _subtotalOf(List<CostItem> items, CostItemType type) {
    final cents = items
        .where((item) => item.itemType == type)
        .fold<int>(0, (sum, item) => sum + (item.itemTotalCost * 100).round());
    return cents / 100;
  }
}
