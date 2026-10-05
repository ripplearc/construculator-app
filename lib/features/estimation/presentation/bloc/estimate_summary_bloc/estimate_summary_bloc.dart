import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'estimate_summary_event.dart';
part 'estimate_summary_state.dart';

/// Loads the estimate a cost sheet is opened from, so the sheet can show its
/// name and running total.
///
/// The database keeps no running total for an estimate, so the loaded
/// estimate's `totalCost` is the sum of its cost items.
///
/// A new request replaces one still loading: only the newest result is
/// emitted, so a reload after an add is never dropped.
class EstimateSummaryBloc
    extends Bloc<EstimateSummaryEvent, EstimateSummaryState> {
  final CostEstimationRepository _repository;
  final CostItemRepository _costItemRepository;
  var _latestRequest = 0;

  EstimateSummaryBloc({
    required this._repository,
    required this._costItemRepository,
  }) : super(const EstimateSummaryInitial()) {
    on<EstimateSummaryRequested>(_onRequested);
  }

  Future<void> _onRequested(
    EstimateSummaryRequested event,
    Emitter<EstimateSummaryState> emit,
  ) async {
    final request = ++_latestRequest;
    emit(const EstimateSummaryLoading());
    final estimate = await _repository.getEstimation(event.estimateId);
    final total = await _costItemRepository.getEstimateItemsTotal(
      event.estimateId,
    );
    if (request != _latestRequest) return;
    estimate.fold(
      (failure) => emit(EstimateSummaryFailure(failure)),
      (loaded) => total.fold(
        (failure) => emit(EstimateSummaryFailure(failure)),
        (sum) => emit(EstimateSummaryLoaded(loaded.copyWith(totalCost: sum))),
      ),
    );
  }
}
