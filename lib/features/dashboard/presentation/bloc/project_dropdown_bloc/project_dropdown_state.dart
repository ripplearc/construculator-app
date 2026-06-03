// coverage:ignore-file

part of 'project_dropdown_bloc.dart';

UnmodifiableListView<Project> _filterByQuery(
  List<Project> projects,
  String query,
) {
  if (query.isEmpty) return UnmodifiableListView(projects);
  final lower = query.toLowerCase();
  return UnmodifiableListView(
    projects
        .where((p) => p.projectName.toLowerCase().contains(lower))
        .toList(),
  );
}

/// Base class for project dropdown states.
abstract class ProjectDropdownState extends Equatable {
  const ProjectDropdownState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any loading starts.
class ProjectDropdownInitial extends ProjectDropdownState {
  const ProjectDropdownInitial();
}

/// State emitted while loading projects.
class ProjectDropdownLoadInProgress extends ProjectDropdownState {
  const ProjectDropdownLoadInProgress();
}

/// State emitted when projects are loaded successfully.
class ProjectDropdownLoadSuccess extends ProjectDropdownState {
  /// The full set of accessible projects, unfiltered.
  final UnmodifiableListView<Project> projects;

  /// The currently selected project, if any.
  final Project? selectedProject;

  /// The active case-insensitive search query applied to [projects].
  final String searchQuery;

  ProjectDropdownLoadSuccess({
    required List<Project> projects,
    required this.selectedProject,
    this.searchQuery = '',
  }) : projects = UnmodifiableListView<Project>(List<Project>.from(projects));

  /// The projects matching [searchQuery]; equals [projects] when the query is
  /// empty. Filtering lives here so the UI renders a pre-filtered list.
  UnmodifiableListView<Project> get visibleProjects =>
      _filterByQuery(projects.toList(), searchQuery);

  ProjectDropdownLoadSuccess copyWith({
    Project? selectedProject,
    String? searchQuery,
  }) {
    return ProjectDropdownLoadSuccess(
      projects: projects.toList(),
      selectedProject: selectedProject ?? this.selectedProject,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [projects, selectedProject, searchQuery];
}

/// State emitted when loading projects fails.
///
/// Carries the last successfully loaded projects in [cachedProjects] (filtered
/// by [searchQuery]) so the UI can keep showing them as a fallback without
/// holding its own copy of BLoC state.
class ProjectDropdownLoadFailure extends ProjectDropdownState {
  /// Human-readable failure message.
  final String message;

  /// The last known projects, retained so the UI can fall back to them.
  final UnmodifiableListView<Project> cachedProjects;

  /// The search query that was active when the failure occurred.
  final String searchQuery;

  ProjectDropdownLoadFailure(
    this.message, {
    List<Project> cachedProjects = const [],
    this.searchQuery = '',
  }) : cachedProjects = UnmodifiableListView<Project>(
         List<Project>.from(cachedProjects),
       );

  /// The cached projects matching [searchQuery]; equals [cachedProjects] when
  /// the query is empty.
  UnmodifiableListView<Project> get visibleProjects =>
      _filterByQuery(cachedProjects.toList(), searchQuery);

  ProjectDropdownLoadFailure copyWith({String? searchQuery}) {
    return ProjectDropdownLoadFailure(
      message,
      cachedProjects: cachedProjects.toList(),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [message, cachedProjects, searchQuery];
}
