// coverage:ignore-file

import 'package:construculator/libraries/project/data/models/project_dto.dart';

/// Data source contract for dashboard project search.
abstract class ProjectSearchDataSource {
  /// Fetches projects matching [query] scoped to the dashboard.
  ///
  /// Returns an empty list immediately when [query] is blank.
  /// Rethrows on RPC failure — callers are responsible for error mapping.
  Future<List<ProjectDto>> fetchProjectsBySearchQuery(String query);
}
