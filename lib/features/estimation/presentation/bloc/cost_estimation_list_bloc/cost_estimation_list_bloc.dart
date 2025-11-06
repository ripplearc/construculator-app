import 'dart:async';
import 'dart:collection';

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';

part 'cost_estimation_list_event.dart';
part 'cost_estimation_list_state.dart';

class CostEstimationListBloc
    extends Bloc<CostEstimationListEvent, CostEstimationListState> {
  final CostEstimationRepository _repository;
  StreamSubscription<Either<Failure, List<CostEstimate>>>? _streamSubscription;

  CostEstimationListBloc({required CostEstimationRepository repository})
    : _repository = repository,
      super(const CostEstimationListInitial()) {
    on<CostEstimationListStartWatching>(_onStartWatching);
    on<_CostEstimationListUpdated>(_onUpdated);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }

  void _onStartWatching(
    CostEstimationListStartWatching event,
    Emitter<CostEstimationListState> emit,
  ) {
    emit(const CostEstimationListLoading());

    _streamSubscription?.cancel();

    _streamSubscription = _repository
        .watchEstimations(event.projectId)
        .distinct(_compareEstimationResults)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((result) {
          add(_CostEstimationListUpdated(result));
        });
  }

  bool _compareEstimationResults(
    Either<Failure, List<CostEstimate>> previous,
    Either<Failure, List<CostEstimate>> current,
  ) {
    return previous.fold(
      (prevFailure) => current.fold(
        (currFailure) =>
            prevFailure.runtimeType == currFailure.runtimeType &&
            prevFailure == currFailure,
        (_) => false,
      ),
      (prevEstimations) => current.fold((_) => false, (currEstimations) {
        if (prevEstimations.length != currEstimations.length) return false;
        for (var i = 0; i < prevEstimations.length; i++) {
          if (prevEstimations[i] != currEstimations[i]) return false;
        }
        return true;
      }),
    );
  }

  void _onUpdated(
    _CostEstimationListUpdated event,
    Emitter<CostEstimationListState> emit,
  ) {
    event.result.fold(
      (failure) {
        final currentEstimations = state is CostEstimationListWithData
            ? (state as CostEstimationListWithData).estimates.toList()
            : <CostEstimate>[];
        emit(
          CostEstimationListError(
            failure: failure,
            estimates: currentEstimations,
          ),
        );
      },
      (estimations) {
        if (estimations.isEmpty) {
          emit(const CostEstimationListEmpty());
        } else {
          emit(CostEstimationListLoaded(estimates: estimations));
        }
      },
    );
  }
}
