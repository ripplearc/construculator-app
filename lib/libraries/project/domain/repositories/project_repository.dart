import 'package:construculator/libraries/project/domain/entities/project_entity.dart';

/// Abstract repository interface for project data operations.
///
/// This repository defines the contract for accessing project data from various
/// data sources (local storage, remote APIs, etc.). It follows the repository
/// pattern to abstract data access logic from the domain layer.
///
/// Details can be found in the detailed design document: https://docs.google.com/document/d/1iXnDtNoersQdjHARELluAMqb8sB96rhRmjMKCWUA3QY/edit?tab=t.9phj9ydk8mav#bookmark=id.2xm61l2g4vgi
abstract class ProjectRepository {
  /// Retrieves a project by its unique identifier.
  ///
  /// Returns a [Future] that completes with a [Project] entity containing
  /// all project details including name, description, creator, company,
  /// export settings, and status.
  Future<Project> getProject(String id);

  /// Retrieves all projects accessible by the given [userId].
  ///
  /// Includes projects created by the user and projects shared with them.
  /// Returns an empty list if [userId] is null or empty.
  Future<List<Project>> getProjects(String userId);

  /// Emits accessible projects whenever project access changes for [userId].
  Stream<List<Project>> watchProjects(String userId);

  /// Releases any resources held by the repository.
  ///
  /// Implementations should cancel active subscriptions and close any
  /// internal controllers to avoid memory leaks.
  void dispose();

  /// Get all permissions for a specific project
  ///
  /// Returns a list of permission keys (e.g., ['edit_cost_estimation', 'get_cost_estimations'])
  /// that the current user has for the specified project.
  ///
  /// Returns an empty list if:
  /// - User is not authenticated
  /// - User has no permissions for the project
  /// - Project ID not found
  ///
  /// **⚠️ IMPORTANT - Permission Staleness:**
  /// Permissions are cached and may become stale after permission-changing operations:
  /// - Accepting project invitations
  /// - Role changes
  /// - Permission updates by project admins
  ///
  /// The repository automatically refreshes cached permissions periodically.
  /// For immediate updates after permission changes, consider implementing
  /// a manual refresh mechanism in your application layer.
  ///
  /// [projectId] The UUID of the project
  List<String> getProjectPermissions(String projectId);

  /// Check if current user has specific permission for project
  ///
  /// Convenience method that checks if [permissionKey] exists in the
  /// permissions list for [projectId].
  ///
  /// **⚠️ IMPORTANT - Permission Staleness:**
  /// Permissions are cached and may become stale after permission-changing
  /// operations (accepting invitations, role changes, etc.).
  ///
  /// The repository automatically refreshes cached permissions periodically.
  /// For immediate updates after permission changes, consider implementing
  /// a manual refresh mechanism in your application layer.
  ///
  /// [projectId] The UUID of the project
  /// [permissionKey] The permission key to check (e.g., 'edit_cost_estimation')
  bool hasProjectPermission(String projectId, String permissionKey);
}
