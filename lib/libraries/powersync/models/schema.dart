// coverage:ignore-file

import 'package:powersync/powersync.dart';

/// Client-side SQLite schema for PowerSync.
///
/// Columns must match the SELECTs in sync-streams.yaml — mismatches cause
/// silent data loss. The `id` column is added automatically by PowerSync.
const schema = Schema([
  Table(
    'professional_roles',
    [
      Column.text('role_name'),
      Column.text('description'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
  ),

  Table(
    'users',
    [
      Column.text('email'),
      Column.text('first_name'),
      Column.text('last_name'),
      Column.text('professional_role'),
      Column.text('user_status'),
      Column.text('user_preferences'),
      Column.text('country_code'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
  ),

  Table(
    'projects',
    [
      Column.text('project_name'),
      Column.text('description'),
      Column.text('creator_user_id'),
      Column.text('owning_company_id'),
      Column.text('export_folder_link'),
      Column.text('export_storage_provider'),
      Column.text('project_status'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('by_creator', [IndexedColumn('creator_user_id')]),
      Index('by_status', [IndexedColumn('project_status')]),
    ],
  ),

  Table(
    'project_members',
    [
      Column.text('project_id'),
      Column.text('user_id'),
      Column.text('role_id'),
      Column.text('membership_status'),
      Column.text('joined_at'),
    ],
    indexes: [
      Index('by_project', [IndexedColumn('project_id')]),
      Index('by_user', [IndexedColumn('user_id')]),
    ],
  ),

  /// On-demand stream: call `db.syncStream('project_cost_data', {'project_id': id})`
  /// when opening a project to populate this table.
  Table(
    'cost_estimates',
    [
      Column.text('project_id'),
      Column.text('estimate_name'),
      Column.text('estimate_description'),
      Column.text('creator_user_id'),
      Column.text('markup_configuration'),
      Column.real('total_cost'),
      /// Boolean stored as integer: 0 = false (unlocked), 1 = true (locked)
      Column.integer('is_locked'),
      Column.text('locked_by_user_id'),
      Column.text('locked_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('by_project', [IndexedColumn('project_id')]),
    ],
  ),
]);
