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

  // The calculator's trade stores (UX Design Doc term 2.16, Appendix B):
  // the editable lists the material keys read. Local-only in version one --
  // no sync stream, no upload queue, never cleared by a sync -- which is
  // what `Table.localOnly` means to PowerSync; CA-1113 (Phase 2) syncs them.
  // Lengths are whole ticks of 1/64 inch, the calculator engine's canonical
  // unit, so a stored 47.24in and a computed area agree to the tick.
  //
  // Three stores of one shape share one table: drywall sheets, masonry
  // pieces and footing cross-sections are all a width and a height, told
  // apart by `store`. `system` keeps both seed sets (Appendix B seeds sheet
  // sizes per unit system) so switching the System of units shows the other
  // set without a reseed. `position` is the user's order, kept in Dart.
  Table.localOnly('calculator_sizes', [
    Column.text('store'),
    Column.text('system'),
    Column.integer('width_ticks'),
    Column.integer('height_ticks'),
    Column.integer('position'),
  ]),

  // On-centre spacings the Qty@OC key offers (16in, 24in).
  Table.localOnly('calculator_spacings', [
    Column.integer('ticks'),
    Column.integer('position'),
  ]),

  // One row: the fence's post spacing and rails per section.
  Table.localOnly('calculator_fence', [
    Column.integer('on_centre_ticks'),
    Column.integer('rails_per_section'),
  ]),

  // One row per rate unit (ft², yd³, sheet, 1,000 bf…), with the waste
  // factor the Waste pill sets for that unit; waste starts at 0%.
  Table.localOnly('calculator_rates', [
    Column.text('unit'),
    Column.real('rate'),
    Column.real('waste_percent'),
  ]),

  // Named densities in lbs/yd³, user-extendable with "+ Add material".
  Table.localOnly('calculator_densities', [
    Column.text('name'),
    Column.real('pounds_per_cubic_yard'),
    Column.integer('position'),
  ]),
]);
