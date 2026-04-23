import 'dart:async';

import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'recent_estimations_event.dart';
part 'recent_estimations_state.dart';

class RecentEstimationsBloc
    extends Bloc<RecentEstimationsEvent, RecentEstimationsState> {
  final WatchRecentEstimationsUseCase _watchRecentEstimationsUseCase;
  StreamSubscription<Either<Failure, List<CostEstimate>>>? _subscription;

  RecentEstimationsBloc({
    required WatchRecentEstimationsUseCase watchRecentEstimationsUseCase,
  }) : _watchRecentEstimationsUseCase = watchRecentEstimationsUseCase,
       super(const RecentEstimationsLoading()) {
    on<RecentEstimationsWatchStarted>(_onWatchStarted);
    on<_RecentEstimationsUpdated>(_onUpdated);
  }

  void _onWatchStarted(
    RecentEstimationsWatchStarted event,
    Emitter<RecentEstimationsState> emit,
  ) {
    // Preserve last known state if available to avoid flicker
    List<CostEstimate>? previousEstimations;
    if (state is RecentEstimationsLoaded) {
      previousEstimations = (state as RecentEstimationsLoaded).estimations;
    } else if (state is RecentEstimationsLoading) {
      previousEstimations =
          (state as RecentEstimationsLoading).lastKnownEstimations;
    }

    emit(RecentEstimationsLoading(lastKnownEstimations: previousEstimations));

    _subscription?.cancel();

    _subscription =
        _watchRecentEstimationsUseCase(const RecentEstimationsParams()).listen((
          result,
        ) {
          add(_RecentEstimationsUpdated(result));
        });
  }

  void _onUpdated(
    _RecentEstimationsUpdated event,
    Emitter<RecentEstimationsState> emit,
  ) {
    event.result.fold(
      (failure) => emit(RecentEstimationsError(failure.toString())),
      (estimations) => emit(RecentEstimationsLoaded(estimations)),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
