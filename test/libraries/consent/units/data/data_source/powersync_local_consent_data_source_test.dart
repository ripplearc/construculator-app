import 'dart:async';

import 'package:construculator/libraries/consent/data/data_source/powersync_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/powersync/testing/fake_powersync_database.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/common.dart';

/// A [FakePowerSyncDatabase] holding consent rows and answering the three
/// statements [PowerSyncLocalConsentDataSource] issues.
///
/// Routes on the table named in the SQL rather than interpreting it: the
/// query text is the data source's business, and a fake that re-implemented
/// SQLite would only be testing itself. Filtering the two `WHERE` clauses is
/// reproduced, because the data source relies on it and a fake that ignored
/// it would let a broken query pass.
///
/// The real thing cannot be used here. PowerSync reads through a native SQLite
/// extension that `flutter test` has no way to load — `libsqlite3.so` is not
/// resolvable in the test VM — so ordering and the `ORDER BY version DESC`
/// itself are verified by review against the schema and by the E2E suite, not
/// by this file. What is under test here is every decision made in Dart:
/// which published version is in force, which record is newest, what the
/// watch stream emits, and what an insert writes.
class _FakeConsentDatabase extends FakePowerSyncDatabase {
  /// Rows in the replicated `consent_versions` table, in arbitrary order.
  /// Column names match `schema.dart`.
  final List<Map<String, Object?>> consentVersions = [];

  /// Rows in the replicated `user_consents` table, in arbitrary order.
  final List<Map<String, Object?>> userConsents = [];

  /// Thrown by the next read of either table, so a caller can exercise a
  /// failing query without a real database.
  Object? readError;

  /// Parameters passed to the most recent [execute] call, for asserting what
  /// an insert wrote.
  List<Object?>? lastExecuteParameters;

  /// The SQL of the most recent [execute] call.
  String? lastExecuteSql;

  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Signals a change to `user_consents`, the way a synced row or a local
  /// write does, so [watch] re-runs its query.
  void notifyChange() => _changes.add(null);

  /// Closes the change stream, ending any [watch] this fake handed out.
  Future<void> closeChanges() => _changes.close();

  @override
  Future<ResultSet> getAll(
    String sql, [
    List<Object?> parameters = const [],
  ]) async => _query(sql, parameters);

  @override
  Future<ResultSet> execute(
    String sql, [
    List<Object?> parameters = const [],
  ]) async {
    lastExecuteSql = sql;
    lastExecuteParameters = parameters;
    return _empty();
  }

  @override
  Stream<ResultSet> watch(
    String sql, {
    List<Object?> parameters = const [],
    Duration throttle = const Duration(milliseconds: 30),
    Iterable<String>? triggerOnTables,
  }) {
    // Subscribes to _changes inside the listen callback, the way
    // sqlite_async's own throttleStream does, and re-runs the query on the
    // immediate tick rather than replaying a value read earlier.
    return Stream<ResultSet>.multi((controller) {
      void emit() {
        try {
          controller.add(_query(sql, parameters));
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      }

      final subscription = _changes.stream.listen(
        (_) => emit(),
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
      emit();
    });
  }

  ResultSet _query(String sql, List<Object?> parameters) {
    final error = readError;
    if (error != null) throw error;

    if (sql.contains('FROM consent_versions')) {
      final matching =
          consentVersions
              .where((row) => row['consent_type'] == parameters[0])
              .toList()
            // Highest version first, which is what the real ORDER BY gives.
            ..sort(
              (a, b) => (b['version']! as int).compareTo(a['version']! as int),
            );
      return _resultSet(matching);
    }

    if (sql.contains('FROM user_consents')) {
      return _resultSet(
        userConsents
            .where(
              (row) =>
                  row['user_id'] == parameters[0] &&
                  row['consent_type'] == parameters[1],
            )
            .toList(),
      );
    }

    throw StateError('Unexpected statement: $sql');
  }

  ResultSet _empty() => ResultSet(const [], null, const []);

  ResultSet _resultSet(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) return _empty();
    final columns = rows.first.keys.toList();
    return ResultSet(columns, null, [
      for (final row in rows) [for (final column in columns) row[column]],
    ]);
  }
}

void main() {
  group('PowerSyncLocalConsentDataSource', () {
    const type = ConsentType.termsAndPrivacy;
    const userId = 'user-1';
    final now = DateTime.utc(2026, 9, 1);

    late _FakeConsentDatabase database;
    late FakeClockImpl clock;
    late PowerSyncLocalConsentDataSource dataSource;

    setUp(() {
      database = _FakeConsentDatabase();
      clock = FakeClockImpl(now);
      // The subject under test; resolving it through Modular would test the
      // module binding instead.
      // ignore: no_direct_instantiation
      dataSource = PowerSyncLocalConsentDataSource(
        database: database,
        clock: clock,
      );
    });

    tearDown(() async {
      await dataSource.dispose();
      await database.closeChanges();
    });

    Map<String, Object?> versionRow({
      required int version,
      DateTime? effectiveFrom,
      ConsentType forType = type,
      Object? rawEffectiveFrom,
    }) => {
      'id': 'version-$version',
      'consent_type': forType.toJson(),
      'version': version,
      'document_url': 'https://example.com/terms/v$version',
      'effective_from':
          rawEffectiveFrom ??
          (effectiveFrom ?? DateTime.utc(2026, 1, 1)).toIso8601String(),
      'published_at': '2026-01-01T00:00:00.000Z',
    };

    Map<String, Object?> consentRow({
      required String id,
      required DateTime recordedAt,
      String forUserId = userId,
      ConsentType forType = type,
      int version = 1,
      ConsentAction action = ConsentAction.accepted,
      Object? rawRecordedAt,
    }) => {
      'id': id,
      'user_id': forUserId,
      'consent_type': forType.toJson(),
      'version': version,
      'action': action.toJson(),
      'recorded_at': rawRecordedAt ?? recordedAt.toIso8601String(),
      'app_version': null,
      'platform': null,
    };

    group('fetchPublishedVersion', () {
      test('is null when nothing has synced yet', () async {
        expect(await dataSource.fetchPublishedVersion(type), isNull);
      });

      test('returns the only version in force', () async {
        database.consentVersions.add(versionRow(version: 1));

        final published = await dataSource.fetchPublishedVersion(type);

        expect(published!.version, 1);
        expect(published.consentType, type);
        expect(published.documentUrl, 'https://example.com/terms/v1');
      });

      // The half of current_consent_versions that says highest version wins.
      test('returns the highest version among those in force', () async {
        database.consentVersions.addAll([
          versionRow(version: 1),
          versionRow(version: 3),
          versionRow(version: 2),
        ]);

        expect((await dataSource.fetchPublishedVersion(type))!.version, 3);
      });

      // The other half: a version published ahead of time is not yet in
      // force, and the version beneath it still binds users until it is.
      test('skips a version whose effective_from has not arrived', () async {
        database.consentVersions.addAll([
          versionRow(version: 1, effectiveFrom: DateTime.utc(2026, 1, 1)),
          versionRow(version: 2, effectiveFrom: DateTime.utc(2026, 12, 1)),
        ]);

        expect((await dataSource.fetchPublishedVersion(type))!.version, 1);
      });

      test(
        'the scheduled version takes over once the clock passes it',
        () async {
          database.consentVersions.addAll([
            versionRow(version: 1, effectiveFrom: DateTime.utc(2026, 1, 1)),
            versionRow(version: 2, effectiveFrom: DateTime.utc(2026, 12, 1)),
          ]);

          clock.set(DateTime.utc(2027, 1, 1));

          expect((await dataSource.fetchPublishedVersion(type))!.version, 2);
        },
      );

      test('is null when every version is still scheduled', () async {
        database.consentVersions.add(
          versionRow(version: 1, effectiveFrom: DateTime.utc(2026, 12, 1)),
        );

        expect(await dataSource.fetchPublishedVersion(type), isNull);
      });

      // Skipping it would report the version beneath as current, marking
      // users satisfied who are not. Throwing resolves to a status that
      // blocks instead.
      test(
        'throws rather than skipping an unreadable effective_from',
        () async {
          database.consentVersions.addAll([
            versionRow(version: 1),
            versionRow(version: 2, rawEffectiveFrom: 'not a timestamp'),
          ]);

          expect(
            () => dataSource.fetchPublishedVersion(type),
            throwsA(isA<FormatException>()),
          );
        },
      );

      // Only rows at or above the answer are inspected, so an unreadable
      // timestamp on a superseded row cannot fail a healthy read.
      test('ignores an unreadable effective_from below the answer', () async {
        database.consentVersions.addAll([
          versionRow(version: 1, rawEffectiveFrom: 'not a timestamp'),
          versionRow(version: 2),
        ]);

        expect((await dataSource.fetchPublishedVersion(type))!.version, 2);
      });

      test('reads only the requested consent type', () async {
        database.consentVersions.add(
          versionRow(version: 5, forType: ConsentType.analytics),
        );

        expect(await dataSource.fetchPublishedVersion(type), isNull);
        expect(
          (await dataSource.fetchPublishedVersion(
            ConsentType.analytics,
          ))!.version,
          5,
        );
      });
    });

    group('fetchLatestUserConsent', () {
      test('is null when the user has no record', () async {
        expect(await dataSource.fetchLatestUserConsent(userId, type), isNull);
      });

      // Newest by recorded_at, not by the order rows come back in — which for
      // a synced table is not insertion order at all.
      test(
        'returns the newest by recordedAt regardless of row order',
        () async {
          database.userConsents.addAll([
            consentRow(id: 'b', recordedAt: DateTime.utc(2026, 8, 20)),
            consentRow(id: 'a', recordedAt: DateTime.utc(2026, 8, 1)),
            consentRow(id: 'c', recordedAt: DateTime.utc(2026, 8, 10)),
          ]);

          expect(
            (await dataSource.fetchLatestUserConsent(userId, type))!.id,
            'b',
          );
        },
      );

      // A withdrawal supersedes the acceptance beneath it; the append-only
      // log means both rows are present and only the newer one decides.
      test('a later withdrawal supersedes the acceptance', () async {
        database.userConsents.addAll([
          consentRow(id: 'a', recordedAt: DateTime.utc(2026, 8, 1)),
          consentRow(
            id: 'b',
            recordedAt: DateTime.utc(2026, 8, 2),
            version: 0,
            action: ConsentAction.withdrawn,
          ),
        ]);

        final latest = await dataSource.fetchLatestUserConsent(userId, type);

        expect(latest!.action, ConsentAction.withdrawn);
        expect(latest.version, 0);
      });

      // Two records sharing an instant must still produce one answer, and the
      // same answer on every device. The id is the primary key, so it is
      // present, unique, and identical wherever the question is asked.
      test(
        'resolves an identical recordedAt by id, deterministically',
        () async {
          final instant = DateTime.utc(2026, 8, 20);
          database.userConsents.addAll([
            consentRow(id: 'aaa', recordedAt: instant),
            consentRow(id: 'zzz', recordedAt: instant),
          ]);

          expect(
            (await dataSource.fetchLatestUserConsent(userId, type))!.id,
            'zzz',
          );

          // Reversing the rows must not reverse the answer — that is the
          // difference between deterministic and merely arbitrary.
          database.userConsents.setAll(0, [
            consentRow(id: 'zzz', recordedAt: instant),
            consentRow(id: 'aaa', recordedAt: instant),
          ]);

          expect(
            (await dataSource.fetchLatestUserConsent(userId, type))!.id,
            'zzz',
          );
        },
      );

      // recorded_at synced from Postgres need not carry the same separator as
      // one this class wrote, and a lexicographic sort over the two would put
      // same-day rows in writer order rather than time order.
      test(
        'orders across a space-separated and a T-separated timestamp',
        () async {
          database.userConsents.addAll([
            consentRow(
              id: 'synced',
              recordedAt: DateTime.utc(2026, 8, 20, 12),
              rawRecordedAt: '2026-08-20 12:00:00Z',
            ),
            consentRow(
              id: 'local',
              recordedAt: DateTime.utc(2026, 8, 20, 9),
              rawRecordedAt: '2026-08-20T09:00:00.000Z',
            ),
          ]);

          expect(
            (await dataSource.fetchLatestUserConsent(userId, type))!.id,
            'synced',
          );
        },
      );

      test('reads only the requested user and type', () async {
        database.userConsents.addAll([
          consentRow(
            id: 'other-user',
            recordedAt: DateTime.utc(2026, 8, 25),
            forUserId: 'user-2',
          ),
          consentRow(
            id: 'other-type',
            recordedAt: DateTime.utc(2026, 8, 26),
            forType: ConsentType.analytics,
          ),
          consentRow(id: 'mine', recordedAt: DateTime.utc(2026, 8, 1)),
        ]);

        expect(
          (await dataSource.fetchLatestUserConsent(userId, type))!.id,
          'mine',
        );
      });

      // An unreadable row is not dropped: the repository resolves a throw to
      // a status that blocks, where a silent skip would report an older
      // record as current.
      test('propagates an unreadable row', () async {
        database.userConsents.add(
          consentRow(
            id: 'a',
            recordedAt: DateTime.utc(2026, 8, 1),
            rawRecordedAt: 'not a timestamp',
          ),
        );

        expect(
          () => dataSource.fetchLatestUserConsent(userId, type),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('watchLatestUserConsent', () {
      test('emits the current record on subscribe', () async {
        database.userConsents.add(
          consentRow(id: 'a', recordedAt: DateTime.utc(2026, 8, 1)),
        );

        await expectLater(
          dataSource.watchLatestUserConsent(userId, type),
          emits(predicate<UserConsentDto?>((r) => r!.id == 'a')),
        );
      });

      test('emits null when the user has no record', () async {
        await expectLater(
          dataSource.watchLatestUserConsent(userId, type),
          emits(isNull),
        );
      });

      test('re-emits when a matching record arrives', () async {
        final expectation = expectLater(
          dataSource.watchLatestUserConsent(userId, type),
          emitsInOrder([
            isNull,
            predicate<UserConsentDto?>((r) => r!.id == 'a'),
          ]),
        );

        database.userConsents.add(
          consentRow(id: 'a', recordedAt: DateTime.utc(2026, 8, 1)),
        );
        database.notifyChange();

        await expectation;
      });

      // The watch fires on any change to user_consents, another user's synced
      // row included, and the query then returns the same answer as before.
      // Without .distinct() the second matcher would land on a repeated null
      // rather than on the record the test is waiting for.
      test('collapses a change that does not alter this answer', () async {
        final expectation = expectLater(
          dataSource.watchLatestUserConsent(userId, type),
          emitsInOrder([
            isNull,
            predicate<UserConsentDto?>((r) => r!.id == 'mine'),
          ]),
        );

        database.userConsents.add(
          consentRow(
            id: 'theirs',
            recordedAt: DateTime.utc(2026, 8, 1),
            forUserId: 'user-2',
          ),
        );
        database.notifyChange();

        database.userConsents.add(
          consentRow(id: 'mine', recordedAt: DateTime.utc(2026, 8, 2)),
        );
        database.notifyChange();

        await expectation;
      });

      test('surfaces a query failure on the stream', () async {
        database.readError = const FormatException('corrupt row');

        await expectLater(
          dataSource.watchLatestUserConsent(userId, type),
          emitsError(isA<FormatException>()),
        );
      });
    });

    group('insertUserConsent', () {
      UserConsentDto draft({
        int version = 2,
        ConsentAction action = ConsentAction.accepted,
        String? appVersion,
        String? platform,
      }) => UserConsentDto.draft(
        userId: userId,
        consentType: type,
        version: version,
        action: action,
        recordedAt: DateTime.utc(2026, 8, 20, 9),
        appVersion: appVersion,
        platform: platform,
      );

      test('assigns an id and returns the record it stored', () async {
        final dto = draft();

        final stored = await dataSource.insertUserConsent(dto);

        expect(stored.id, isNotNull);
        expect(stored.id, isNot(isEmpty));
        expect(stored.userId, dto.userId);
        expect(stored.consentType, dto.consentType);
        expect(stored.version, dto.version);
        expect(stored.action, dto.action);
        expect(stored.recordedAt, dto.recordedAt);
      });

      test('assigns a distinct id per insert', () async {
        final first = await dataSource.insertUserConsent(draft());
        final second = await dataSource.insertUserConsent(draft());

        expect(first.id, isNot(second.id));
      });

      test('writes the assigned id and the wire values', () async {
        final stored = await dataSource.insertUserConsent(
          draft(version: 0, action: ConsentAction.withdrawn),
        );

        expect(database.lastExecuteSql, contains('INSERT INTO user_consents'));
        expect(
          database.lastExecuteParameters,
          containsAll(<Object?>[
            stored.id,
            userId,
            'terms_and_privacy',
            0,
            'withdrawn',
          ]),
        );
      });

      // recorded_at orders a history across devices, so it is normalised to
      // UTC on the way in rather than stored as the writer's local time.
      test('writes recordedAt as a UTC timestamp', () async {
        await dataSource.insertUserConsent(draft());

        expect(
          database.lastExecuteParameters,
          contains('2026-08-20T09:00:00.000Z'),
        );
      });

      // toInsertJson omits null audit metadata, so the column list has to
      // shrink with it or the placeholders stop lining up.
      test('omits the audit columns when they are null', () async {
        await dataSource.insertUserConsent(draft());

        expect(database.lastExecuteSql, isNot(contains('app_version')));
        expect(database.lastExecuteSql, isNot(contains('platform')));
        expect(database.lastExecuteParameters, hasLength(6));
      });

      test('includes the audit columns when they are set', () async {
        await dataSource.insertUserConsent(
          draft(appVersion: '1.2.3', platform: 'ios'),
        );

        expect(database.lastExecuteSql, contains('app_version'));
        expect(database.lastExecuteParameters, containsAll(['1.2.3', 'ios']));
        expect(database.lastExecuteParameters, hasLength(8));
      });
    });

    group('dispose', () {
      // ConsentRepositoryImpl.dispose calls this precisely because it knows
      // nobody is listening any more, so the streams it handed out have to
      // end rather than stay open forever.
      test('closes the streams watchLatestUserConsent handed out', () async {
        final events = <UserConsentDto?>[];
        final firstEvent = Completer<void>();
        final subscription = dataSource
            .watchLatestUserConsent(userId, type)
            .listen((event) {
              events.add(event);
              if (!firstEvent.isCompleted) firstEvent.complete();
            });

        // Waited for rather than assumed. The in-memory store queued its
        // first value on the caller's own controller inside listen(), so it
        // survived an immediate dispose; this one travels through the
        // database's watch stream first, and disposing before it lands
        // cancels it in transit. Nothing depends on that value arriving --
        // the repository disposes at module teardown, not mid-subscription --
        // so the assertion below is about the stream ending, not about it.
        await firstEvent.future;
        // Taken before dispose: asFuture only completes on a done event that
        // has yet to be delivered.
        final closed = subscription.asFuture<void>();

        await dataSource.dispose();

        await expectLater(closed, completes);
        expect(events, [isNull]);
      });

      test('closes every open watcher, not just the first', () async {
        final first = dataSource.watchLatestUserConsent(userId, type);
        final second = dataSource.watchLatestUserConsent(
          userId,
          ConsentType.analytics,
        );
        final expectation = expectLater(
          Future.wait([first.drain<void>(), second.drain<void>()]),
          completes,
        );

        await dataSource.dispose();

        await expectation;
      });

      // Only a live subscription can be tracked, so a stream taken out before
      // dispose but subscribed to after it would otherwise run untracked and
      // never end. It answers once and closes, which is what closing the
      // in-memory store's change controller did to a late subscriber.
      test(
        'a stream subscribed to after dispose answers once, then ends',
        () async {
          database.userConsents.add(
            consentRow(id: 'a', recordedAt: DateTime.utc(2026, 8, 1)),
          );
          final stream = dataSource.watchLatestUserConsent(userId, type);

          await dataSource.dispose();

          await expectLater(
            stream,
            emitsInOrder([
              predicate<UserConsentDto?>((r) => r!.id == 'a'),
              emitsDone,
            ]),
          );
        },
      );

      test('is safe to call twice', () async {
        await dataSource.dispose();

        await expectLater(dataSource.dispose(), completes);
      });

      // The database belongs to PowerSyncModule and other libraries read the
      // same instance, so this source must not close it out from under them.
      test('does not close the database', () async {
        await dataSource.dispose();

        expect(
          await dataSource.fetchLatestUserConsent(userId, type),
          isNull,
          reason: 'reads must still work after the source is disposed',
        );
      });
    });
  });
}
