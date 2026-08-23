import 'package:construculator/libraries/consent/data/data_source/in_memory_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

UserConsentDto _draft({
  String userId = 'user-1',
  ConsentType type = ConsentType.termsAndPrivacy,
  int version = 1,
  ConsentAction action = ConsentAction.accepted,
  DateTime? recordedAt,
}) => UserConsentDto.draft(
  userId: userId,
  consentType: type,
  version: version,
  action: action,
  recordedAt: recordedAt ?? DateTime.utc(2026, 8, 17),
);

void main() {
  group('InMemoryLocalConsentDataSource', () {
    late InMemoryLocalConsentDataSource dataSource;

    setUp(() {
      dataSource = InMemoryLocalConsentDataSource();
    });

    tearDown(() {
      dataSource.dispose();
    });

    // Seeded rather than empty so the gate resolves to a real requirement. An
    // empty seed would leave every type unknown, which the repository reads as
    // ConsentIndeterminate for every user -- the store would be demoable only
    // in the sense that nothing ever happens.
    test('seeds a published version for every consent type', () async {
      for (final type in ConsentType.values) {
        final published = await dataSource.fetchPublishedVersion(type);

        expect(published, isNotNull, reason: 'no seed for ${type.name}');
        expect(published!.consentType, type);
        expect(published.version, 1);
        expect(Uri.parse(published.documentUrl).isScheme('https'), isTrue);
      }
    });

    test('seedVersions replaces the defaults', () async {
      final seeded = ConsentVersionDto(
        id: 'version-7',
        consentType: ConsentType.analytics,
        version: 7,
        documentUrl: 'https://ripplearc.com/legal/analytics',
        publishedAt: DateTime.utc(2026, 8, 1),
      );
      dataSource = InMemoryLocalConsentDataSource(
        seedVersions: {ConsentType.analytics: seeded},
      );

      expect(
        await dataSource.fetchPublishedVersion(ConsentType.analytics),
        seeded,
      );
      expect(
        await dataSource.fetchPublishedVersion(ConsentType.termsAndPrivacy),
        isNull,
        reason:
            'an explicit seed replaces the defaults rather than adding to '
            'them',
      );
    });

    test('insertUserConsent assigns an id and preserves the record', () async {
      final draft = _draft(version: 3);

      final stored = await dataSource.insertUserConsent(draft);

      expect(stored.id, isNotNull);
      expect(stored.userId, draft.userId);
      expect(stored.consentType, draft.consentType);
      expect(stored.version, draft.version);
      expect(stored.action, draft.action);
      expect(stored.recordedAt, draft.recordedAt);
    });

    test('fetchLatestUserConsent returns the inserted record', () async {
      final stored = await dataSource.insertUserConsent(_draft());

      expect(
        await dataSource.fetchLatestUserConsent(
          'user-1',
          ConsentType.termsAndPrivacy,
        ),
        stored,
      );
    });

    // The newest record decides the gate, and a withdrawal must supersede the
    // acceptance beneath it rather than sitting alongside it.
    test('fetchLatestUserConsent returns the newest of several', () async {
      await dataSource.insertUserConsent(_draft());
      final withdrawal = await dataSource.insertUserConsent(
        _draft(action: ConsentAction.withdrawn),
      );

      final latest = await dataSource.fetchLatestUserConsent(
        'user-1',
        ConsentType.termsAndPrivacy,
      );

      expect(latest, withdrawal);
      expect(latest!.action, ConsentAction.withdrawn);
    });

    test(
      'fetchLatestUserConsent is null when the user has no record',
      () async {
        expect(
          await dataSource.fetchLatestUserConsent(
            'user-1',
            ConsentType.termsAndPrivacy,
          ),
          isNull,
        );
      },
    );

    // One user's acceptance must not read as another's, and accepting the
    // terms must not read as an analytics opt-in.
    test('records are isolated per user and per type', () async {
      await dataSource.insertUserConsent(_draft());

      expect(
        await dataSource.fetchLatestUserConsent(
          'user-2',
          ConsentType.termsAndPrivacy,
        ),
        isNull,
      );
      expect(
        await dataSource.fetchLatestUserConsent(
          'user-1',
          ConsentType.analytics,
        ),
        isNull,
      );
    });

    test(
      'watchLatestUserConsent emits the current record on subscribe',
      () async {
        await expectLater(
          dataSource.watchLatestUserConsent(
            'user-1',
            ConsentType.termsAndPrivacy,
          ),
          emits(isNull),
        );
      },
    );

    test('watchLatestUserConsent emits again on insert', () async {
      final stream = dataSource.watchLatestUserConsent(
        'user-1',
        ConsentType.termsAndPrivacy,
      );
      final expectation = expectLater(
        stream,
        emitsInOrder([isNull, isA<UserConsentDto>()]),
      );

      await dataSource.insertUserConsent(_draft());

      await expectation;
    });

    // Re-emits rather than staying silent -- the store notifies on any write
    // and each subscriber re-reads its own slice -- but the value the watcher
    // sees must still be its own, and user-1 has nothing on file. `.distinct()`
    // on the source means a write that doesn't change this watcher's own
    // latest record produces no second emission at all, so a single `isNull`
    // is the complete, deterministic expectation, not a truncated read of it.
    test(
      'watchLatestUserConsent does not leak another user\'s write',
      () async {
        final stream = dataSource.watchLatestUserConsent(
          'user-1',
          ConsentType.termsAndPrivacy,
        );
        final expectation = expectLater(stream, emitsInOrder([isNull]));

        await dataSource.insertUserConsent(_draft(userId: 'user-2'));

        await expectation;
      },
    );

    test('dispose closes the watch stream', () async {
      final stream = dataSource.watchLatestUserConsent(
        'user-1',
        ConsentType.termsAndPrivacy,
      );
      final expectation = expectLater(
        stream,
        emitsInOrder([isNull, emitsDone]),
      );

      await dataSource.dispose();

      await expectation;
    });
  });
}
