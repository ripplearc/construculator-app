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
  static const String costEstimationLogsTable = 'cost_estimate_logs';
  static const String costItemsTable = 'cost_items';
  static const String projectsTable = 'projects';
  static const String projectMembersTable = 'project_members';
  static const String searchHistoryTable = 'search_history';

  // RPC function names
  static const String globalSearchRpcFunction = 'global_search';
  static const String searchSuggestionsRpcFunction = 'get_search_suggestions';

  // Column names
  static const String idColumn = 'id';
  static const String projectIdColumn = 'project_id';
  static const String userIdColumn = 'user_id';
  static const String creatorUserIdColumn = 'creator_user_id';
  static const String createdAtColumn = 'created_at';
  static const String estimateNameColumn = 'estimate_name';
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

  // Search history columns
  static const String searchTermColumn = 'search_term';
  static const String scopeColumn = 'scope';
  static const String searchCountColumn = 'search_count';
  static const String hasResultsColumn = 'has_results';

  /// Unique constraint columns for search_history upsert.
  /// Used with [SupabaseWrapper.upsert] onConflict parameter.
  static const String searchHistoryUpsertConflictColumns =
      '$userIdColumn,$searchTermColumn,$scopeColumn';

  // User profile columns (id field uses the shared idColumn above)
  static const String credentialIdColumn = 'credential_id';
  static const String firstNameColumn = 'first_name';
  static const String lastNameColumn = 'last_name';
  static const String professionalRoleColumn = 'professional_role';
  static const String profilePhotoUrlColumn = 'profile_photo_url';

  // Cost Estimation Logs columns
  static const String estimateIdColumn = 'estimate_id';
  static const String activityColumn = 'activity';
  static const String userColumn = 'user';
  static const String activityDetailsColumn = 'activity_details';
  static const String loggedAtColumn = 'logged_at';
}
