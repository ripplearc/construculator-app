// coverage:ignore-file
/// Centralized permission key constants.
///
/// This file contains all permission keys used across the application for
/// authorization checks. These keys must match the permission keys defined
/// in the database.
///
/// When adding new permissions, add them here first, then reference them
/// in your repositories, data sources, and UI components.
class PermissionConstants {
  PermissionConstants._();

  // Cost Estimation permissions
  static const String getCostEstimations = 'get_cost_estimations';
  static const String addCostEstimation = 'add_cost_estimation';
  static const String deleteCostEstimation = 'delete_cost_estimation';
  static const String editCostEstimation = 'edit_cost_estimation';
  static const String lockCostEstimation = 'lock_cost_estimation';

  // Project permissions
  static const String viewProject = 'view_project';
  static const String editProject = 'edit_project';
  static const String deleteProject = 'delete_project';
}
