/// Centralized database table and column name constants.
///
/// This file contains all database table names and column names used across
/// the application. This ensures consistency and makes it easier to maintain
/// database schema changes in the future.
///
/// When adding new tables or columns, add them here first, then reference
/// them in your data sources and repositories.
class DatabaseConstants {
  // Private constructor to prevent instantiation
  DatabaseConstants._();

  // Table names
  static const String costEstimatesTable = 'cost_estimates';
  static const String projectsTable = 'projects';
  static const String projectMembersTable = 'project_members';

  // Column names
  static const String idColumn = 'id';
  static const String projectIdColumn = 'project_id';
  static const String userIdColumn = 'user_id';
  static const String creatorUserIdColumn = 'creator_user_id';
  static const String createdAtColumn = 'created_at';
  static const String updatedAtColumn = 'updated_at';
  static const String statusColumn = 'status';
  static const String isLockedColumn = 'is_locked';
  static const String lockedByUserIdColumn = 'locked_by_user_id';
  static const String lockedAtColumn = 'locked_at';
  static const String projectNameColumn = 'project_name';
  static const String descriptionColumn = 'description';
  static const String owningCompanyIdColumn = 'owning_company_id';
  static const String exportFolderLinkColumn = 'export_folder_link';
  static const String exportStorageProviderColumn = 'export_storage_provider';
}
