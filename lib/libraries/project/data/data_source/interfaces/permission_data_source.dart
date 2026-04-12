/// Data source for accessing user permission data.
///
/// This abstraction provides access to permission information stored in JWT claims
/// or other authentication/authorization sources.
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
  ///
  /// [projectId] The UUID of the project
  /// [permissionKey] The permission key to check (e.g., 'edit_cost_estimation')
  bool hasProjectPermission(String projectId, String permissionKey);
}
