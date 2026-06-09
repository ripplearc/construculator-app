import 'package:construculator/libraries/project/data/models/project_dto.dart';

/// Data source contract for dashboard project search.
abstract class ProjectSearchDataSource {
  /// Returns projects matching [query] scoped to the dashboard.
  ///
  /// Returns an empty list immediately when [query] is blank.
  /// Rethrows on RPC failure — callers are responsible for error mapping.
  Future<List<ProjectDto>> searchProjects(String query);
}
