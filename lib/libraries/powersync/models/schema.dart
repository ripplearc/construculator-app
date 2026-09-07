// coverage:ignore-file

import 'package:powersync/powersync.dart';

/// Client-side SQLite schema for PowerSync.
///
/// Columns must match the SELECTs in sync-streams.yaml — mismatches cause
/// silent data loss. The `id` column is added automatically by PowerSync.
const Schema schema = Schema([
  Table('professional_roles', [
    Column.text('role_name'),
    Column.text('description'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  Table('users', [
    Column.text('email'),
    Column.text('first_name'),
    Column.text('last_name'),
    Column.text('professional_role'),
    Column.text('user_status'),
    Column.text('user_preferences'),
    Column.text('country_code'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

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

  // The full publication history, not just the version currently in force.
  // The backend has a `current_consent_versions` view that resolves "in
  // force", but a sync stream replicates a base table's WAL and a view has no
  // replication identity to follow -- and the view's own predicate is
  // `effective_from <= now()`, which no row change fires, so a version
  // scheduled to go live next month would never enter the stream. That is why
  // `effective_from` is synced: PowerSyncLocalConsentDataSource applies the
  // view's two rules itself (effective_from in the past, highest version
  // wins). Unindexed -- a handful of rows per consent type.
  Table('consent_versions', [
    Column.text('consent_type'),
    Column.integer('version'),
    Column.text('document_url'),
    Column.text('effective_from'),
    Column.text('published_at'),
  ]),

  Table(
    'user_consents',
    [
      Column.text('user_id'),
      Column.text('consent_type'),
      Column.integer('version'),
      Column.text('action'),
      Column.text('recorded_at'),
      Column.text('app_version'),
      Column.text('platform'),
    ],
    indexes: [
      // Equality on both columns, which is the whole of the only query the
      // gate runs against this table. Deliberately two columns where the
      // backend's `user_consents_user_type_recorded_idx` has three: the
      // trailing `recorded_at DESC` earns its place there because Postgres
      // sorts on that column, while here the newest row is picked in Dart
      // rather than by SQL. A `recorded_at` synced from Postgres and one
      // written locally need not be the same text format, and a lexicographic
      // ORDER BY across the two would sort by which side wrote the row rather
      // than by time -- see PowerSyncLocalConsentDataSource.
      Index('by_user_type', [
        IndexedColumn('user_id'),
        IndexedColumn('consent_type'),
      ]),
    ],
  ),

  // On-demand stream: call `db.syncStream('user_cost_estimates')` when the
  // user enters the cost estimation feature. Membership and the
  // `get_cost_estimations` permission are derived from the JWT server-side,
  // so no parameters are passed from the client.
  Table(
    'cost_estimates',
    [
      Column.text('project_id'),
      Column.text('estimate_name'),
      Column.text('estimate_description'),
      Column.text('creator_user_id'),
      Column.text('markup_type'),
      Column.text('overall_markup_value_type'),
      Column.real('overall_markup_value'),
      Column.text('material_markup_value_type'),
      Column.real('material_markup_value'),
      Column.text('labor_markup_value_type'),
      Column.real('labor_markup_value'),
      Column.text('equipment_markup_value_type'),
      Column.real('equipment_markup_value'),
      Column.real('total_cost'),

      // Boolean stored as integer: 0 = false (unlocked), 1 = true (locked)
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
