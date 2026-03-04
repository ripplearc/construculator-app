import 'dart:async';

import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:construculator/libraries/project/data/data_source/interfaces/project_data_source.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:construculator/libraries/project/domain/repositories/project_repository.dart';
import 'package:construculator/libraries/supabase/interfaces/supabase_wrapper.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:flutter_modular/flutter_modular.dart';

/// Remote implementation of the project repository.
class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectDataSource _projectDataSource;
  final SupabaseWrapper _supabaseWrapper;
  final Clock _clock;
  static final _logger = AppLogger().tag('ProjectRepositoryImpl');
  StreamController<List<Project>>? _projectsController;
  StreamSubscription<void>? _projectChangesSubscription;
  List<Project> _lastEmittedProjects = const [];
  bool _isRefreshing = false;

  ProjectRepositoryImpl({
    required ProjectDataSource projectDataSource,
    required SupabaseWrapper supabaseWrapper,
    Clock? clock,
  }) : _projectDataSource = projectDataSource,
       _supabaseWrapper = supabaseWrapper,
       _clock = clock ?? Modular.get<Clock>();

  @override
  Future<Project> getProject(String id) async {
    try {
      // TODO: https://ripplearc.youtrack.cloud/issue/CA-162/Dashboard-Create-Project-Repository
      return Project(
        id: id,
        projectName: 'Sample Construction Project',
        description: 'A sample construction project for testing purposes',
        creatorUserId: 'user_123',
        owningCompanyId: 'company_456',
        exportFolderLink: 'https://drive.google.com/sample-folder',
        exportStorageProvider: StorageProvider.googleDrive,
        createdAt: _clock.now(),
        updatedAt: _clock.now(),
        status: ProjectStatus.active,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting project by id: $id, error: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<List<Project>> getProjects() async {
    try {
      final userId = _supabaseWrapper.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final ownedProjects = await _projectDataSource.getOwnedProjects(userId);
      final sharedProjects = await _projectDataSource.getSharedProjects(userId);

      final projectsById = <String, Project>{};
      for (final projectDto in [...ownedProjects, ...sharedProjects]) {
        final project = projectDto.toDomain();
        projectsById[project.id] = project;
      }

      final projects = projectsById.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return projects;
    } catch (error, stackTrace) {
      _logger.error(
        'Error while getting accessible projects: $error',
        stackTrace.toString(),
      );
      rethrow;
    }
  }

  @override
  Stream<List<Project>> watchProjects() {
    _projectsController ??= StreamController<List<Project>>.broadcast(
      onListen: _startWatchingProjectChanges,
      onCancel: _stopWatchingIfNoListeners,
    );

    return _projectsController!.stream;
  }

  void _startWatchingProjectChanges() {
    if (_projectChangesSubscription != null) {
      return;
    }

    final userId = _supabaseWrapper.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _emitProjects(const []);
      return;
    }

    _projectChangesSubscription = _projectDataSource
        .watchProjectChanges(userId)
        .listen(
          (_) => _refreshProjects(),
          onError: (Object error, StackTrace stackTrace) {
            _logger.error(
              'Error while watching project changes: $error',
              stackTrace.toString(),
            );
            _projectsController?.addError(error, stackTrace);
          },
        );

    _refreshProjects();
  }

  void _stopWatchingIfNoListeners() {
    if (_projectsController?.hasListener == true) {
      return;
    }
    _projectChangesSubscription?.cancel();
    _projectChangesSubscription = null;
    _lastEmittedProjects = const [];
  }

  Future<void> _refreshProjects() async {
    if (_isRefreshing) {
      return;
    }
    _isRefreshing = true;

    try {
      final projects = await getProjects();
      _emitProjects(projects);
    } catch (error, stackTrace) {
      _logger.error(
        'Error while refreshing accessible projects: $error',
        stackTrace.toString(),
      );
      _projectsController?.addError(error, stackTrace);
    } finally {
      _isRefreshing = false;
    }
  }

  void _emitProjects(List<Project> projects) {
    if (_projectsAreEqual(_lastEmittedProjects, projects)) {
      return;
    }

    _lastEmittedProjects = List<Project>.from(projects);
    if (_projectsController?.isClosed == false) {
      _projectsController?.add(projects);
    }
  }

  bool _projectsAreEqual(List<Project> first, List<Project> second) {
    if (identical(first, second)) {
      return true;
    }
    if (first.length != second.length) {
      return false;
    }
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }
    return true;
  }
}
