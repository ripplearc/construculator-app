import 'dart:async';
import 'dart:collection';

import 'package:construculator/features/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_estimation_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/transformers.dart';

part 'cost_estimation_list_event.dart';
part 'cost_estimation_list_state.dart';

class CostEstimationListBloc
    extends Bloc<CostEstimationListEvent, CostEstimationListState> {
  final CostEstimationRepository _repository;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<Either<Failure, List<CostEstimate>>>? _streamSubscription;
  StreamSubscription<String?>? _projectChangeSubscription;
  String? _activeProjectId;
  static final _logger = AppLogger().tag('CostEstimationListBloc');

  CostEstimationListBloc({
    required CostEstimationRepository repository,
    required CurrentProjectNotifier currentProjectNotifier,
  }) : _repository = repository,
       _currentProjectNotifier = currentProjectNotifier,
       super(const CostEstimationListInitial()) {
    on<CostEstimationListStartWatching>(_onStartWatching);
    on<CostEstimationListLoadMore>(_onLoadMore);
    on<CostEstimationListRefresh>(_onRefreshed);
    on<_CostEstimationListUpdated>(_onUpdated);
    on<_CostEstimationListProjectUnavailable>(_onProjectUnavailable);
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    _projectChangeSubscription?.cancel();
    return super.close();
  }

  void _onStartWatching(
    CostEstimationListStartWatching event,
    Emitter<CostEstimationListState> emit,
  ) {
    _ensureProjectChangeListener();

    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null) {
      _streamSubscription?.cancel();
      _streamSubscription = null;
      _activeProjectId = null;
      _logger.error('Current project ID is null, cannot manage estimations');
      _emitProjectUnavailableError(emit);
      return;
    }

    emit(const CostEstimationListLoading());

    _streamSubscription?.cancel();
    _activeProjectId = projectId;

    _streamSubscription = _repository
        .watchEstimations(projectId)
        .distinct(_compareEstimationResults)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((result) {
          final hasMore = _repository.hasMoreEstimations(projectId);
          add(_CostEstimationListUpdated(result, hasMore: hasMore));
        });
  }

  void _ensureProjectChangeListener() {
    _projectChangeSubscription ??= _currentProjectNotifier
        .onCurrentProjectChanged
        .listen((projectId) {
          if (isClosed || projectId == _activeProjectId) return;

          if (projectId == null) {
            add(const _CostEstimationListProjectUnavailable());
            return;
          }

          add(const CostEstimationListStartWatching());
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

  Future<void> _onRefreshed(
    CostEstimationListRefresh event,
    Emitter<CostEstimationListState> emit,
  ) async {
    if (state is CostEstimationListLoading) return;

    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null) {
      _logger.error('Current project ID is null, cannot manage estimations');
      _emitProjectUnavailableError(
        emit,
        estimates: state is CostEstimationListWithData
            ? (state as CostEstimationListWithData).estimates.toList()
            : const <CostEstimate>[],
        hasMore: state is CostEstimationListWithData
            ? (state as CostEstimationListWithData).hasMore
            : true,
      );
      return;
    }

    await _repository.fetchInitialEstimations(projectId);
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
        final currentHasMore = state is CostEstimationListWithData
            ? (state as CostEstimationListWithData).hasMore
            : true;
        emit(
          CostEstimationListError(
            failure: failure,
            estimates: currentEstimations,
            hasMore: currentHasMore,
          ),
        );
      },
      (estimations) {
        if (estimations.isEmpty) {
          emit(const CostEstimationListEmpty());
        } else {
          emit(
            CostEstimationListLoaded(
              estimates: estimations,
              hasMore: event.hasMore,
            ),
          );
        }
      },
    );
  }

  void _onProjectUnavailable(
    _CostEstimationListProjectUnavailable event,
    Emitter<CostEstimationListState> emit,
  ) {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _activeProjectId = null;

    _logger.error('Current project ID is null, cannot manage estimations');

    _emitProjectUnavailableError(
      emit,
      estimates: state is CostEstimationListWithData
          ? (state as CostEstimationListWithData).estimates.toList()
          : const <CostEstimate>[],
      hasMore: state is CostEstimationListWithData
          ? (state as CostEstimationListWithData).hasMore
          : true,
    );
  }

  Future<void> _onLoadMore(
    CostEstimationListLoadMore event,
    Emitter<CostEstimationListState> emit,
  ) async {
    if (state is! CostEstimationListLoaded) return;

    final projectId = _currentProjectNotifier.currentProjectId;
    if (projectId == null) {
      final currentState = state as CostEstimationListLoaded;
      _logger.error('Current project ID is null, cannot manage estimations');
      _emitProjectUnavailableError(
        emit,
        estimates: currentState.estimates.toList(),
        hasMore: currentState.hasMore,
      );
      return;
    }

    final currentState = state as CostEstimationListLoaded;

    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    final result = await _repository.loadMoreEstimations(projectId);

    result.fold((failure) {}, (estimations) {
      final hasMore = _repository.hasMoreEstimations(projectId);

      emit(currentState.copyWith(hasMore: hasMore, isLoadingMore: false));
    });
  }

  void _emitProjectUnavailableError(
    Emitter<CostEstimationListState> emit, {
    List<CostEstimate> estimates = const <CostEstimate>[],
    bool hasMore = true,
  }) {
    emit(
      CostEstimationListError(
        failure: UnexpectedFailure(),
        estimates: estimates,
        hasMore: hasMore,
      ),
    );
  }
}
