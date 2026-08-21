import 'dart:async';

import 'package:construculator/features/dashboard/domain/usecases/watch_recent_estimations_usecase.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/interfaces/current_project_notifier.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'recent_estimations_event.dart';
part 'recent_estimations_state.dart';

/// Manages the [WatchRecentEstimationsUseCase] stream and exposes
/// [RecentEstimationsLoading], [RecentEstimationsLoaded], and
/// [RecentEstimationsError] states for the dashboard UI.
class RecentEstimationsBloc
    extends Bloc<RecentEstimationsEvent, RecentEstimationsState> {
  static final _logger = AppLogger().tag('RecentEstimationsBloc');
  final WatchRecentEstimationsUseCase _watchRecentEstimationsUseCase;
  final CurrentProjectNotifier _currentProjectNotifier;
  StreamSubscription<Either<Failure, List<CostEstimate>>>? _subscription;
  StreamSubscription<String?>? _projectSubscription;

  String? get currentProjectId => _currentProjectNotifier.currentProjectId;

  /// Defines constructor that takes a usecase as an injected dependency.
  RecentEstimationsBloc({
    required this._watchRecentEstimationsUseCase,
    required this._currentProjectNotifier,
  }) : super(const RecentEstimationsLoading()) {
    on<RecentEstimationsWatchStarted>(_onWatchStarted);
    on<_RecentEstimationsProjectChanged>(_onProjectChanged);
    on<_RecentEstimationsUpdated>(_onUpdated);
  }

  void _onWatchStarted(
    RecentEstimationsWatchStarted event,
    Emitter<RecentEstimationsState> emit,
  ) {
    _projectSubscription ??= _currentProjectNotifier.onCurrentProjectChanged
        .listen((_) => add(const _RecentEstimationsProjectChanged()));

    List<CostEstimate>? previousEstimations;
    if (state is RecentEstimationsLoaded) {
      previousEstimations = (state as RecentEstimationsLoaded).estimations;
    } else if (state is RecentEstimationsLoading) {
      previousEstimations =
          (state as RecentEstimationsLoading).lastKnownEstimations;
    }

    emit(RecentEstimationsLoading(lastKnownEstimations: previousEstimations));

    _subscription?.cancel();

    // No project selected yet (right after login, before the project
    // dropdown's auto-selection lands): stay in loading instead of
    // surfacing a failure banner — the project-changed listener above
    // re-dispatches this event once a selection arrives (CA-900).
    // Zero-project accounts never get a selection and stay here; CA-984
    // models that state distinctly.
    // https://ripplearc.youtrack.cloud/issue/CA-984
    final projectId = currentProjectId;
    if (projectId == null || projectId.isEmpty) {
      _subscription = null;
      return;
    }

    _subscription = _watchRecentEstimationsUseCase(
      const RecentEstimationsParams(),
    ).listen(
      (result) {
        add(_RecentEstimationsUpdated(result));
      },
      onError: (Object error, StackTrace stackTrace) {
        // The use case surfaces expected failures as Left values; a raw
        // stream error would otherwise escape to the zone handler and
        // leave the section stuck on the loading state. Warning-level:
        // error() belongs at the stream-owning data boundary, not in a bloc.
        _logger.warning('Recent estimations stream errored', error, stackTrace);
        add(
          _RecentEstimationsUpdated(
            Left(error is Failure ? error : UnexpectedFailure()),
          ),
        );
      },
    );
  }

  void _onProjectChanged(
    _RecentEstimationsProjectChanged event,
    Emitter<RecentEstimationsState> emit,
  ) {
    add(const RecentEstimationsWatchStarted());
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
    _projectSubscription?.cancel();
    _subscription?.cancel();
    return super.close();
  }
}
