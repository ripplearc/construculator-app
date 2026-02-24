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

  // Column names
  static const String idColumn = 'id';
  static const String projectIdColumn = 'project_id';
  static const String createdAtColumn = 'created_at';
  static const String estimateNameColumn = 'estimate_name';
  static const String isLockedColumn = 'is_locked';
  static const String lockedByUserIdColumn = 'locked_by_user_id';
  static const String lockedAtColumn = 'locked_at';
}
