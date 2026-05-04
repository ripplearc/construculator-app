import 'package:construculator/libraries/auth/domain/entities/user_profile_entity.dart';
import 'package:construculator/libraries/estimation/domain/entities/cost_estimate_entity.dart';
import 'package:construculator/libraries/project/domain/entities/project_entity.dart';
import 'package:equatable/equatable.dart';

/// Domain entity representing the results of a global search.
///
/// Holds the matched [projects], cost [estimations], and [members] returned
/// after executing a search query against the backend.
///
/// All lists default to empty, so callers can always iterate without null checks.
class SearchResults extends Equatable {
  /// Projects matching the search query.
  final List<Project> projects;

  /// Cost estimations matching the search query.
  final List<CostEstimate> estimations;

  /// Team members matching the search query.
  final List<UserProfile> members;

  const SearchResults({
    this.projects = const [],
    this.estimations = const [],
    this.members = const [],
  });

  /// Returns a copy of this [SearchResults] with the given fields replaced.
  SearchResults copyWith({
    List<Project>? projects,
    List<CostEstimate>? estimations,
    List<UserProfile>? members,
  }) {
    return SearchResults(
      projects: projects ?? this.projects,
      estimations: estimations ?? this.estimations,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [projects, estimations, members];
}
