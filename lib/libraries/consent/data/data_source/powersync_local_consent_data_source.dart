import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/interfaces/local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:powersync/powersync.dart';

/// Reads and writes consent data through PowerSync's local SQLite database.
///
/// The offline-first store CA-971 puts behind [LocalConsentDataSource], in
/// place of the in-memory stand-in that lost every acceptance on restart.
/// Reads never touch the network: rows arrive through the `consent_versions`
/// and `user_consents` sync streams, and a write lands locally first and is
/// queued for upload by PowerSync's own CRUD queue.
///
/// Takes a [PowerSyncDatabase] rather than the wider `SqliteConnection` it
/// implements. What this class does is PowerSync's rather than SQLite's: the
/// tables are views whose INSTEAD OF triggers are what enqueue an upload, and
/// [insertUserConsent] mints its primary key with the SDK's own `uuid`
/// generator because the server has not seen the row yet.
///
/// ## Ordering is resolved in Dart, not in SQL
///
/// Both reads sort their candidate rows in Dart. That looks like a missed
/// `ORDER BY`, and it is deliberate.
///
/// `recorded_at`, `effective_from` and `published_at` are `timestamptz` on the
/// server and TEXT in SQLite, and the rows in these tables come from two
/// writers: PowerSync replicating from Postgres, and [insertUserConsent]
/// writing locally through [UserConsentDto.toInsertJson]. Nothing guarantees
/// the two produce the same text format — a space separator versus a `T`
/// differ at index 10 of the string, so a lexicographic `ORDER BY` over rows
/// from both writers sorts same-day rows by which side wrote them rather than
/// by when they happened. `DateTime.parse` accepts either spelling, so
/// parsing first and comparing [DateTime]s is correct whatever the replicator
/// emits, and the row counts make it free: a handful of published versions per
/// type, and one user's decisions on one document.
///
/// This is why `user_consents` is indexed on `(user_id, consent_type)` alone
/// in `schema.dart`, where the backend's index carries a third `recorded_at`
/// column. The equality half of the lookup is all SQLite is asked to do.
class PowerSyncLocalConsentDataSource implements LocalConsentDataSource {
  final PowerSyncDatabase _database;
  final Clock _clock;

  /// Live [watchLatestUserConsent] subscriptions, keyed by the controller
  /// feeding the caller and valued by the query subscription feeding it, so
  /// [dispose] can end the streams this source handed out.
  final Map<
    MultiStreamController<UserConsentDto?>,
    StreamSubscription<UserConsentDto?>
  >
  _watchers = {};

  var _disposed = false;

  /// Creates a store over a PowerSync database, using a clock to decide which
  /// published version is in force.
  PowerSyncLocalConsentDataSource({
    required this._database,
    required this._clock,
  });

  static const _versionColumns =
      '${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.consentTypeColumn}, '
      '${DatabaseConstants.versionColumn}, '
      '${DatabaseConstants.documentUrlColumn}, '
      '${DatabaseConstants.effectiveFromColumn}, '
      '${DatabaseConstants.publishedAtColumn}';

  static const _userConsentColumns =
      '${DatabaseConstants.idColumn}, '
      '${DatabaseConstants.userIdColumn}, '
      '${DatabaseConstants.consentTypeColumn}, '
      '${DatabaseConstants.versionColumn}, '
      '${DatabaseConstants.actionColumn}, '
      '${DatabaseConstants.recordedAtColumn}, '
      '${DatabaseConstants.appVersionColumn}, '
      '${DatabaseConstants.platformColumn}';

  /// Candidate published versions for one type, highest version first.
  ///
  /// `version` is an integer column, so this one `ORDER BY` is safe to leave
  /// to SQLite — it is the timestamp columns that cannot be sorted as text.
  static const _publishedVersionsSql =
      'SELECT $_versionColumns '
      'FROM ${DatabaseConstants.consentVersionsTable} '
      'WHERE ${DatabaseConstants.consentTypeColumn} = ? '
      'ORDER BY ${DatabaseConstants.versionColumn} DESC';

  /// One user's history for one document. Unordered by design; see the class
  /// doc.
  static const _userConsentHistorySql =
      'SELECT $_userConsentColumns '
      'FROM ${DatabaseConstants.userConsentsTable} '
      'WHERE ${DatabaseConstants.userIdColumn} = ? '
      'AND ${DatabaseConstants.consentTypeColumn} = ?';

  @override
  Future<ConsentVersionDto?> fetchPublishedVersion(ConsentType type) async {
    final rows = await _database.getAll(_publishedVersionsSql, [type.toJson()]);

    // The same two rules `current_consent_versions` applies on the server:
    // highest version wins among those whose effective_from has passed. The
    // ORDER BY supplies the first half, so the first in-force row is the
    // answer.
    final now = _clock.now();
    for (final row in rows) {
      final effectiveFrom = parseTimestamp(
        row[DatabaseConstants.effectiveFromColumn],
      );

      // Not skipped. A version whose effective_from cannot be read might be
      // in force, and skipping it would hand back the next version down --
      // reporting a *lower* requirement as current, which marks users
      // satisfied who are not. Throwing resolves to a status that blocks,
      // the same direction ConsentVersionDto takes on its own gate fields.
      if (effectiveFrom == null) {
        throw FormatException(
          'Unreadable consent version row: '
          '${DatabaseConstants.effectiveFromColumn}',
        );
      }

      if (!effectiveFrom.isAfter(now)) return ConsentVersionDto.fromJson(row);
    }

    // Either nothing has synced yet, or every version is still scheduled.
    // Both mean the requirement is unknown, which is a status rather than an
    // error -- see LocalConsentDataSource.fetchPublishedVersion.
    return null;
  }

  @override
  Future<UserConsentDto?> fetchLatestUserConsent(
    String userId,
    ConsentType type,
  ) async => _newest(
    await _database.getAll(_userConsentHistorySql, [userId, type.toJson()]),
  );

  @override
  Stream<UserConsentDto?> watchLatestUserConsent(
    String userId,
    ConsentType type,
  ) {
    // triggerOnTables rather than letting watch() detect them: without it,
    // sqlite_async runs EXPLAIN QUERY PLAN first and only subscribes to the
    // update stream after that future completes. The table this query reads
    // is not in doubt, and naming it keeps the subscription synchronous with
    // listen().
    final rows = _database.watch(
      _userConsentHistorySql,
      parameters: [userId, type.toJson()],
      triggerOnTables: const [DatabaseConstants.userConsentsTable],
    );

    // `.distinct()` for the reason the in-memory store needed it: the watch
    // fires on any change to user_consents, including another user's row
    // arriving over sync, and re-running the query then re-emits an answer
    // identical to the last one. UserConsentDto is Equatable, so identical
    // results collapse.
    //
    // The in-memory store's other workaround is NOT carried over. It wrapped
    // its emissions in Stream.multi because an `async*` generator subscribed
    // to the change controller a turn after listen(), and a write landing in
    // that window fired into a controller nobody was listening to and was
    // lost. sqlite_async already closes that window: watch() -> onChange() ->
    // UpdateNotification.throttleStream is itself built on Stream.multi and
    // subscribes to the update stream inside the listen callback, and its
    // triggerImmediately event re-runs the query rather than replaying a value
    // read earlier -- so nothing can land unobserved between the two. _tracked
    // below does use Stream.multi, for dispose, not for this.
    return _tracked(rows.map(_newest).distinct());
  }

  @override
  Future<UserConsentDto> insertUserConsent(UserConsentDto dto) async {
    // `uuid` is PowerSync's own generator, exported from the SDK for exactly
    // this -- a client-assigned primary key for a row the server has not seen
    // yet. Minted here rather than read back from an INSERT ... RETURNING,
    // which SQLite does not offer on a view with an INSTEAD OF trigger, and
    // that is what a PowerSync table is. A v4 UUID also matches the column's
    // server-side type and its `gen_random_uuid()` default.
    final id = uuid.v4();

    // Columns come from the DTO's own serializer, so the wire values and the
    // UTC normalisation of recorded_at have one definition rather than two.
    // toInsertJson omits app_version and platform when null, which is why the
    // column list is built from the map instead of being written out.
    // Interpolated into SQL, but every key is a DatabaseConstants literal.
    final values = {DatabaseConstants.idColumn: id, ...dto.toInsertJson()};
    await _database.execute(
      'INSERT INTO ${DatabaseConstants.userConsentsTable} '
      '(${values.keys.join(', ')}) '
      'VALUES (${List.filled(values.length, '?').join(', ')})',
      values.values.toList(),
    );

    return UserConsentDto.stored(
      id: id,
      userId: dto.userId,
      consentType: dto.consentType,
      version: dto.version,
      action: dto.action,
      recordedAt: dto.recordedAt,
      appVersion: dto.appVersion,
      platform: dto.platform,
    );
  }

  /// Ends every stream [watchLatestUserConsent] handed out.
  ///
  /// The database itself is not closed here: `PowerSyncModule` owns it and
  /// other libraries read the same instance. What this source owns is the
  /// watchers, and `ConsentRepositoryImpl.dispose` calls this precisely
  /// because it knows nobody is listening any more -- a contract the
  /// in-memory store met by closing its change controller.
  @override
  Future<void> dispose() async {
    // Set before the streams are torn down, so a subscription taken out
    // while this is in flight sees a disposed source rather than being
    // tracked into a map that has already been drained.
    _disposed = true;

    // Drained into a list first: closing a watcher runs its onCancel, which
    // removes it from _watchers, and mutating the map under iteration throws.
    final open = _watchers.entries.toList();
    _watchers.clear();
    await Future.wait(
      open.map((watcher) async {
        await watcher.value.cancel();
        await watcher.key.close();
      }),
    );
  }

  // The newest record in the rows, or null when there are none.
  //
  // Newest by recordedAt, with id breaking a tie. The id is the primary key,
  // so it is present on every row, unique, and the same on every device --
  // two records sharing an instant therefore resolve to one answer, and to
  // the *same* answer wherever the question is asked, which is what
  // LocalConsentDataSource asks for. It carries no recency: a UUID is not
  // ordered by when it was minted, so the tie-break is arbitrary but stable
  // rather than "the later write wins". Reaching it needs two decisions on
  // one document inside a single microsecond, which no path through the UI
  // produces.
  UserConsentDto? _newest(Iterable<Map<String, dynamic>> rows) {
    UserConsentDto? newest;
    for (final row in rows) {
      final candidate = UserConsentDto.fromJson(row);
      if (newest == null || _supersedes(candidate, newest)) newest = candidate;
    }
    return newest;
  }

  bool _supersedes(UserConsentDto candidate, UserConsentDto incumbent) {
    final byTime = candidate.recordedAt.compareTo(incumbent.recordedAt);
    if (byTime != 0) return byTime > 0;
    return (candidate.id ?? '').compareTo(incumbent.id ?? '') > 0;
  }

  // Re-exposes the source stream through a controller this source can close.
  Stream<UserConsentDto?> _tracked(Stream<UserConsentDto?> source) =>
      Stream<UserConsentDto?>.multi((controller) {
        // Read on listen, not when the stream was built: a caller can hold a
        // stream across dispose, and only a live subscription can be tracked.
        // After dispose there is nothing left to keep watching, so a late
        // subscriber gets the current answer once and then a done event --
        // what closing the in-memory store's change controller did to one.
        final disposed = _disposed;
        final subscription = (disposed ? source.take(1) : source).listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );

        if (disposed) {
          controller.onCancel = subscription.cancel;
          return;
        }

        _watchers[controller] = subscription;
        controller.onCancel = () {
          _watchers.remove(controller);
          return subscription.cancel();
        };
      });
}
