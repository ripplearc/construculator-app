import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_local_consent_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeLocalConsentDataSource', () {
    const type = ConsentType.termsAndPrivacy;
    const userId = 'user-1';

    late FakeLocalConsentDataSource fake;

    setUp(() {
      fake = FakeLocalConsentDataSource();
    });

    tearDown(() => fake.dispose());

    ConsentVersionDto version(int number) => ConsentVersionDto(
      id: 'version-$number',
      consentType: type,
      version: number,
      documentUrl: 'https://example.com/terms/v$number',
      publishedAt: DateTime.utc(2026, 8, 11),
    );

    UserConsentDto record(
      String forUserId,
      ConsentType forType,
      int number,
      ConsentAction action,
    ) => UserConsentDto(
      id: 'record-$number',
      userId: forUserId,
      consentType: forType,
      version: number,
      action: action,
      recordedAt: DateTime.utc(2026, 8, 11),
    );

    group('fetchPublishedVersion', () {
      test('returns null when nothing has been published', () async {
        final result = await fake.fetchPublishedVersion(type);

        expect(result, isNull);
      });

      test('returns the version set on publishedVersions', () async {
        fake.publishedVersions[type] = version(2);

        final result = await fake.fetchPublishedVersion(type);

        expect(result, version(2));
      });

      test('throws the configured publishedVersionReadError', () async {
        fake.publishedVersionReadError = const FormatException('corrupt row');

        expect(
          () => fake.fetchPublishedVersion(type),
          throwsA(isA<FormatException>()),
        );
      });

      test('is not affected by latestConsentReadError', () async {
        fake.publishedVersions[type] = version(2);
        fake.latestConsentReadError = Exception('local read failed');

        final result = await fake.fetchPublishedVersion(type);

        expect(result, version(2));
      });
    });

    group('fetchLatestUserConsent', () {
      test('returns null when there is no record', () async {
        final result = await fake.fetchLatestUserConsent(userId, type);

        expect(result, isNull);
      });

      test('returns only the record matching the requested user', () async {
        await fake.seedLatestConsent(
          record(userId, type, 1, ConsentAction.accepted),
        );
        await fake.seedLatestConsent(
          record('user-2', type, 2, ConsentAction.accepted),
        );

        final result = await fake.fetchLatestUserConsent(userId, type);

        expect(result!.userId, userId);
        expect(result.version, 1);
      });

      test('returns only the record matching the requested type', () async {
        await fake.seedLatestConsent(
          record(userId, ConsentType.termsAndPrivacy, 1, ConsentAction.accepted),
        );
        await fake.seedLatestConsent(
          record(userId, ConsentType.analytics, 2, ConsentAction.accepted),
        );

        final result = await fake.fetchLatestUserConsent(userId, type);

        expect(result!.consentType, ConsentType.termsAndPrivacy);
        expect(result.version, 1);
      });

      test('throws the configured latestConsentReadError', () async {
        fake.latestConsentReadError = const FormatException('corrupt row');

        expect(
          () => fake.fetchLatestUserConsent(userId, type),
          throwsA(isA<FormatException>()),
        );
      });

      test('is not affected by publishedVersionReadError', () async {
        await fake.seedLatestConsent(
          record(userId, type, 1, ConsentAction.accepted),
        );
        fake.publishedVersionReadError = Exception('published read failed');

        final result = await fake.fetchLatestUserConsent(userId, type);

        expect(result!.version, 1);
      });
    });

    group('insertUserConsent', () {
      test('records the inserted dto in insertedRecords', () async {
        final dto = record(userId, type, 3, ConsentAction.accepted);

        await fake.insertUserConsent(dto);

        expect(fake.insertedRecords, [dto]);
      });

      test('excludes records seeded through seedLatestConsent', () async {
        await fake.seedLatestConsent(
          record(userId, type, 1, ConsentAction.accepted),
        );
        await fake.insertUserConsent(
          record(userId, type, 2, ConsentAction.accepted),
        );

        expect(fake.insertedRecords, hasLength(1));
        expect(fake.insertedRecords.single.version, 2);
      });

      test('becomes visible to a subsequent fetchLatestUserConsent', () async {
        await fake.insertUserConsent(
          record(userId, type, 4, ConsentAction.accepted),
        );

        final result = await fake.fetchLatestUserConsent(userId, type);

        expect(result!.version, 4);
      });

      test('throws the configured writeError without recording', () async {
        fake.writeError = Exception('offline');

        await expectLater(
          () => fake.insertUserConsent(
            record(userId, type, 5, ConsentAction.accepted),
          ),
          throwsException,
        );
        expect(fake.insertedRecords, isEmpty);
      });
    });

    group('watchLatestUserConsent', () {
      test('emits the current record on subscribe', () async {
        await fake.seedLatestConsent(
          record(userId, type, 1, ConsentAction.accepted),
        );

        final result = await fake.watchLatestUserConsent(userId, type).first;

        expect(result!.version, 1);
      });

      test('emits the newest record after insertUserConsent', () async {
        final emitted = expectLater(
          fake.watchLatestUserConsent(userId, type),
          emits(predicate<UserConsentDto?>((r) => r!.version == 6)),
        );

        await fake.insertUserConsent(
          record(userId, type, 6, ConsentAction.accepted),
        );
        await emitted;
      });

      test('does not emit for a write to a different user or type', () async {
        final results = <UserConsentDto?>[];
        final subscription = fake
            .watchLatestUserConsent(userId, type)
            .listen(results.add);

        await fake.insertUserConsent(
          record('user-2', type, 1, ConsentAction.accepted),
        );
        await fake.insertUserConsent(
          record(userId, ConsentType.analytics, 1, ConsentAction.accepted),
        );
        await pumpEventQueue();

        expect(results, [isNull]);
        await subscription.cancel();
      });
    });

    group('dispose', () {
      test('closes the watch stream', () async {
        final stream = fake.watchLatestUserConsent(userId, type);

        await fake.dispose();

        await expectLater(stream.drain<void>(), completes);
      });
    });
  });
}
