import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'estimate_summary_event.dart';
part 'estimate_summary_state.dart';

/// Loads the estimate a cost sheet is opened from, so the sheet can show its
/// name and running total, and keeps the name current when the estimate
/// changes on this phone or another one.
///
/// The `total_cost` column of an estimate can be out of date, so the loaded
/// estimate's `totalCost` is the sum of its cost items instead.
///
/// The sum of the cost items is read once for each request, not again for each
/// change to the estimate row. A new request replaces the one before it: only
/// the newest request is followed, so a reload after an add is never dropped.
class EstimateSummaryBloc
    extends Bloc<EstimateSummaryEvent, EstimateSummaryState> {
  final CostEstimationRepository _repository;
  final CostItemRepository _costItemRepository;

  EstimateSummaryBloc({
    required this._repository,
    required this._costItemRepository,
  }) : super(const EstimateSummaryInitial()) {
    on<EstimateSummaryRequested>(
      _onRequested,
      transformer: (events, mapper) => events.switchMap(mapper),
    );
  }

  Future<void> _onRequested(
    EstimateSummaryRequested event,
    Emitter<EstimateSummaryState> emit,
  ) async {
    emit(const EstimateSummaryLoading());
    final total = _costItemRepository.getEstimateItemsTotal(event.estimateId);
    await emit.forEach(
      _repository
          .watchEstimation(event.estimateId)
          .asyncMap((estimate) async => (estimate, await total)),
      onData: (result) {
        final (estimate, total) = result;
        return estimate.fold(
          EstimateSummaryFailure.new,
          (loaded) => total.fold(
            EstimateSummaryFailure.new,
            (sum) => EstimateSummaryLoaded(loaded.copyWith(totalCost: sum)),
          ),
        );
      },
    );
  }
}
