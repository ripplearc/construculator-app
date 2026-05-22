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

const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

EventTransformer<E> _debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);

/// BLoC for managing project search state on the dashboard.
///
/// Handles debounced query updates and explicit search submissions, plus the
/// recent-searches and suggestions surfaces shown on the idle state.
/// Delegates to [ProjectSearchRepository] and maps results to typed states.
class ProjectSearchBloc extends Bloc<ProjectSearchEvent, ProjectSearchState> {
  final ProjectSearchRepository _repository;
  final AuthManager _authManager;
  static final _logger = AppLogger().tag('ProjectSearchBloc');

  List<String> _cachedRecents = const [];
  List<String> _cachedSuggestions = const [];

  /// Creates a [ProjectSearchBloc] with the given [repository] and [authManager].
  ProjectSearchBloc({
    required ProjectSearchRepository repository,
    required AuthManager authManager,
  }) : _repository = repository,
       _authManager = authManager,
       super(const ProjectSearchInitial()) {
    on<ProjectSearchQueryUpdatedEvent>(
      (event, emit) => _handleQuery(event.query, emit),
      transformer: _debounce(_kQueryDebounceDuration),
    );
    on<ProjectSearchPerformedEvent>(_onPerformed);
    on<ProjectSearchHistoryRequestedEvent>(_onHistoryRequested);
  }

  Future<void> _handleQuery(
    String query,
    Emitter<ProjectSearchState> emit,
  ) async {
    if (query.trim().isEmpty) {
      emit(const ProjectSearchInitial());
      return;
    }
    await _executeSearch(query, emit);
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

  Future<void> _onHistoryRequested(
    ProjectSearchHistoryRequestedEvent event,
    Emitter<ProjectSearchState> emit,
  ) async {
    final userId = _authManager.getCurrentCredentials().data?.id;
    if (userId == null || userId.isEmpty) {
      _logger.warning('History request aborted: no authenticated user');
      emit(const ProjectSearchInitial());
      return;
    }

    emit(
      ProjectSearchInitial(
        recentSearches: _cachedRecents,
        suggestions: _cachedSuggestions,
        isLoadingHistory: true,
      ),
    );

    final results = await Future.wait([
      _repository.getRecentProjectSearches(userId: userId),
      _repository.getProjectSearchSuggestions(userId: userId),
    ]);

    final recents = results[0].fold<List<String>>(
      (failure) {
        _logger.warning('Failed to load recent project searches: $failure');
        return const [];
      },
      (terms) => terms,
    );
    final suggestions = results[1].fold<List<String>>(
      (failure) {
        _logger.warning('Failed to load project search suggestions: $failure');
        return const [];
      },
      (terms) => terms,
    );

    _cachedRecents = recents;
    _cachedSuggestions = suggestions;

    emit(_initialFromCache());
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

  ProjectSearchInitial _initialFromCache() => ProjectSearchInitial(
    recentSearches: _cachedRecents,
    suggestions: _cachedSuggestions,
  );
}
