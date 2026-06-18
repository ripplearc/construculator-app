/// Provides access to project-scoped permission data for the current user.
abstract class ProjectPermissionDataSource {
  /// Get all permissions for a specific project.
  ///
  /// Returns a list of permission keys (e.g., ['edit_cost_estimation', 'get_cost_estimations'])
  /// that the current user has for the specified project.
  ///
  /// Returns an empty list if:
  /// - User is not authenticated
  /// - User has no permissions for the project
  /// - Project ID not found in the permission source
  ///
  /// [projectId] The UUID of the project
  List<String> getProjectPermissions(String projectId);

  /// Check if user has a specific permission for a project.
  ///
  /// Convenience method that checks if [permissionKey] exists in the
  /// permissions list for [projectId].
  /// This must remain synchronous because callers use it as a local JWT claim
  /// lookup and gate mutations before starting async data-source operations.
  ///
  /// [projectId] The UUID of the project
  /// [permissionKey] The permission key to check (e.g., 'edit_cost_estimation')
  bool hasProjectPermission(String projectId, String permissionKey);
}
