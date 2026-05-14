import 'package:construculator/libraries/auth/domain/types/auth_types.dart';
import 'package:construculator/libraries/auth/interfaces/auth_manager.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_search_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'project_search_event.dart';
part 'project_search_state.dart';

/// Debounce duration applied to [ProjectSearchQueryUpdatedEvent] events.
///
/// Kept here so the BLoC owns the contract — no UI-side debouncing required.
const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

/// BLoC for managing project search state on the dashboard.
///
/// Handles debounced query updates and explicit search submissions, delegating
/// to [ProjectSearchRepository] and mapping results to typed states.
class ProjectSearchBloc extends Bloc<ProjectSearchEvent, ProjectSearchState> {
  final ProjectSearchRepository _repository;
  final AuthManager _authManager;
  static final _logger = AppLogger().tag('ProjectSearchBloc');

  /// Creates a [ProjectSearchBloc] with the given [repository] and [authManager].
  ProjectSearchBloc({
    required ProjectSearchRepository repository,
    required AuthManager authManager,
  }) : _repository = repository,
       _authManager = authManager,
       super(const ProjectSearchInitial()) {
    on<ProjectSearchQueryUpdatedEvent>(
      _onQueryUpdated,
      transformer: _debounce(_kQueryDebounceDuration),
    );
    on<ProjectSearchPerformedEvent>(_onPerformed);
  }

  Future<void> _onQueryUpdated(
    ProjectSearchQueryUpdatedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const ProjectSearchInitial());
      return;
    }
    await _executeSearch(event.query, emit);
  }

  Future<void> _onPerformed(
    ProjectSearchPerformedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const ProjectSearchInitial());
      return;
    }
    await _executeSearch(event.query, emit);
  }

  Future<void> _executeSearch(
    String query,
    Emitter<ProjectSearchState> emit,
  ) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('Project search aborted: no authenticated user');
      emit(
        ProjectSearchFailureState(
          failure: const AuthFailure(errorType: AuthErrorType.userNotFound),
          query: query,
        ),
      );
      return;
    }

    emit(ProjectSearchLoading(query: query));

    final result = await _repository.searchProjects(
      userId: userId,
      query: query,
    );

    result.fold(
      (failure) {
        _logger.warning('Project search failed: $failure');
        emit(ProjectSearchFailureState(failure: failure, query: query));
      },
      (projects) =>
          emit(ProjectSearchResultsLoaded(results: projects, query: query)),
    );
  }
}
