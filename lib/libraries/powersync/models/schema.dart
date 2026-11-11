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

  // Never uploaded or synced: `company_users` has no sync access, so the
  // device keeps the one company id the resolver looked up. Every save
  // replaces the single row, which is tagged with the user it was looked up
  // for.
  Table.localOnly('current_company', [
    Column.text('user_id'),
    Column.text('company_id'),
  ]),

  // Never uploaded or synced. One row per refused Your rates item of one
  // user of one company, with the YourRateRefusalKey of the item as its id.
  // `refused_row_id` is the id of the your_rates row the server refused.
  // `accepted_amount` is null when the server never accepted a price;
  // `shown_at` is null until shown.
  // TODO: [CA-1399] register this table as "clear when the user changes", so a user's old rows do not pile up on a shared phone.
  // https://ripplearc.youtrack.cloud/issue/CA-1399
  Table.localOnly('your_rate_refusals', [
    Column.text('user_id'),
    Column.text('company_id'),
    Column.text('category'),
    Column.text('refused_row_id'),
    Column.text('item_name'),
    Column.text('equipment_method'),
    Column.text('entry_label'),
    Column.real('refused_amount'),
    Column.real('accepted_amount'),
    Column.text('shown_at'),
  ]),

  // On-demand stream: call `db.syncStream('user_rates')` before reading. The
  // backend's `item_name_key` column is generated server-side and not synced.
  Table(
    'your_rates',
    [
      Column.text('company_id'),
      Column.text('category'),
      Column.text('item_name'),
      Column.real('rate_amount'),
      Column.text('rate_currency'),
      Column.text('unit'),
      Column.text('equipment_method'),
      Column.text('entry_label'),
      Column.text('saved_at'),
      Column.text('last_used_at'),
      Column.text('created_at'),
      Column.text('updated_at'),
    ],
    indexes: [
      Index('by_company_category', [
        IndexedColumn('company_id'),
        IndexedColumn('category'),
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
  // the editable lists the material keys read. Synced by the auto-subscribed
  // `user_calculator_stores` stream (Design Appendices E.4), filtered on the
  // server to the signed-in user's rows, so these follow the account: a size
  // typed on one phone is offered on every phone, and sign-out clears them
  // with the other synced tables. Only what the user added or changed is a
  // row; Appendix B's defaults ship in the app and are laid over at read
  // time, so a fresh account has no rows at all.
  //
  // `values` is the row's fields as one JSON object, a text column here and
  // jsonb on the server; its keys belong to TradeStoreRowMapper, which keeps
  // every length in whole ticks of 1/64 inch so a stored size and a computed
  // area agree to the tick. A changed default carries the default's key in
  // "seed". `deleted_at` is synced so a delete made on one phone hides the
  // row, or the default it stands for, on the others. Columns match the
  // stream's SELECT; the index is the one read the app makes.
  Table(
    'user_calculator_stores',
    [
      Column.text('user_id'),
      Column.text('store_kind'),
      Column.text('values'),
      Column.text('unit_system'),
      Column.text('created_at'),
      Column.text('updated_at'),
      Column.text('deleted_at'),
    ],
    indexes: [
      Index('by_user_kind', [
        IndexedColumn('user_id'),
        IndexedColumn('store_kind'),
      ]),
    ],
  ),

  // The remembered values the memory drawers offer back (UX Design Doc
  // term 2.11, rule 4.16): one row per value, under the function key that
  // filed it or the one shared angle drawer, newest first by `position`.
  // Local-only and never synced: a recent belongs to the phone it was
  // typed on. A value is its dimension, its canonical magnitude (ticks,
  // square ticks, cubic feet, hundredths of a pound, degrees or a bare
  // number) and the unit it was spelled in, empty for an angle or a bare
  // number.
  // TODO: [CA-1399] register this table as "clear when the user changes", so a second account on the same phone is never offered the first account's recents.
  // https://ripplearc.youtrack.cloud/issue/CA-1399
  Table.localOnly('calculator_recents', [
    Column.text('drawer'),
    Column.integer('position'),
    Column.text('dimension'),
    Column.real('magnitude'),
    Column.text('unit'),
  ]),
]);
