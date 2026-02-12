/// Interface that abstracts project data source operations.
///
/// This allows the project repository to work with any project backend.
abstract class ProjectDataSource {
  /// Checks whether a user has a specific permission on a project.
  ///
  /// Calls the remote RPC function to verify the user's permission.
  ///
  /// [projectId] The ID of the project to check permission for.
  /// [permissionKey] The permission key to check (e.g., "get_cost_estimations").
  /// [userCredentialId] The credential ID of the user to check.
  ///
  /// Returns `true` if the user has the specified permission, `false` otherwise.
  Future<bool> hasPermission({
    required String projectId,
    required String permissionKey,
    required String userCredentialId,
  });
}
