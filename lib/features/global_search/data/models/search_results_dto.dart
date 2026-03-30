import 'package:construculator/features/estimation/data/models/cost_estimate_dto.dart';
import 'package:construculator/libraries/auth/data/models/user_profile_dto.dart';
import 'package:construculator/libraries/project/data/models/project_dto.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for global search results.
///
/// Holds projects, estimations, and members returned from the `global_search`
/// RPC.
// TODO: https://ripplearc.youtrack.cloud/issue/CA-576/DashboardGlobal-Search-Add-calculations-to-SearchResultsDto
class SearchResultsDto extends Equatable {
  final List<ProjectDto> projects;
  final List<CostEstimateDto> estimations;
  final List<UserProfileDto> members;

  const SearchResultsDto({
    this.projects = const [],
    this.estimations = const [],
    this.members = const [],
  });

  @override
  List<Object?> get props => [projects, estimations, members];
}
