import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_remote_consent_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeRemoteConsentDataSource', () {
    late FakeRemoteConsentDataSource fake;

    setUp(() {
      fake = FakeRemoteConsentDataSource();
    });

    ConsentVersionDto version(int number) => ConsentVersionDto(
      id: 'version-$number',
      consentType: ConsentType.termsAndPrivacy,
      version: number,
      documentUrl: 'https://example.com/terms/v$number',
      publishedAt: DateTime.utc(2026, 8, 11),
    );

    group('fetchPublishedVersions', () {
      test('returns publishedVersionsToReturn', () async {
        fake.publishedVersionsToReturn = [version(1), version(2)];

        final result = await fake.fetchPublishedVersions();

        expect(result, [version(1), version(2)]);
      });

      test('returns an empty list by default', () async {
        final result = await fake.fetchPublishedVersions();

        expect(result, isEmpty);
      });

      test('increments callCount on every call', () async {
        await fake.fetchPublishedVersions();
        await fake.fetchPublishedVersions();

        expect(fake.callCount, 2);
      });

      test(
        'throws error on every call when failuresBeforeSuccess is unset',
        () async {
          fake.error = Exception('offline');

          await expectLater(fake.fetchPublishedVersions(), throwsException);
          await expectLater(fake.fetchPublishedVersions(), throwsException);
          expect(fake.callCount, 2);
        },
      );

      test(
        'throws for calls at or below failuresBeforeSuccess, then succeeds',
        () async {
          fake.error = Exception('offline');
          fake.failuresBeforeSuccess = 2;
          fake.publishedVersionsToReturn = [version(1)];

          await expectLater(fake.fetchPublishedVersions(), throwsException);
          await expectLater(fake.fetchPublishedVersions(), throwsException);
          final result = await fake.fetchPublishedVersions();

          expect(result, [version(1)]);
          expect(fake.callCount, 3);
        },
      );

      test(
        'does not throw once callCount exceeds failuresBeforeSuccess even if error is still set',
        () async {
          // Pins the off-by-one in `callCount <= limit`: the boundary call
          // itself still throws, only calls past it succeed.
          fake.error = Exception('offline');
          fake.failuresBeforeSuccess = 1;
          fake.publishedVersionsToReturn = [version(1)];

          await expectLater(fake.fetchPublishedVersions(), throwsException);
          final result = await fake.fetchPublishedVersions();

          expect(result, [version(1)]);
        },
      );

      test(
        'errorSequence throws a different error per call, then falls back to error',
        () async {
          fake.errorSequence.addAll([
            Exception('first call fails one way'),
            Exception('second call fails another way'),
          ]);
          fake.error = Exception('subsequent calls fail this way');
          fake.publishedVersionsToReturn = [version(1)];

          await expectLater(fake.fetchPublishedVersions(), throwsException);
          await expectLater(fake.fetchPublishedVersions(), throwsException);
          // errorSequence is exhausted; falls back to error, which is unset
          // to failuresBeforeSuccess so it throws on every remaining call.
          await expectLater(fake.fetchPublishedVersions(), throwsException);
          expect(fake.callCount, 3);
        },
      );

      test('delaySequence delays each successive call in order', () async {
        fake.delaySequence.addAll([
          const Duration(milliseconds: 5),
          const Duration(milliseconds: 15),
        ]);
        fake.publishedVersionsToReturn = [version(1)];

        final stopwatch = Stopwatch()..start();
        await fake.fetchPublishedVersions();
        final firstElapsed = stopwatch.elapsed;
        stopwatch
          ..reset()
          ..start();
        await fake.fetchPublishedVersions();
        final secondElapsed = stopwatch.elapsed;

        expect(
          firstElapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 5)),
        );
        expect(
          secondElapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 15)),
        );
      });
    });
  });
}
