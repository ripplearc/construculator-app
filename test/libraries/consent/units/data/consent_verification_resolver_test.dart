import 'package:construculator/libraries/consent/data/consent_verification_resolver.dart';
import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_remote_consent_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentVerificationResolver', () {
    const type = ConsentType.termsAndPrivacy;

    late FakeRemoteConsentDataSource remoteDataSource;
    late ConsentVerificationResolver resolver;

    setUp(() {
      remoteDataSource = FakeRemoteConsentDataSource();
      resolver = ConsentVerificationResolver(remoteDataSource);
    });

    ConsentVersionDto published({int version = 1}) => ConsentVersionDto(
      id: 'version-$version',
      consentType: type,
      version: version,
      documentUrl: 'https://example.com/terms/v$version',
      publishedAt: DateTime.utc(2026, 8, 11),
    );

    group('when the server has no row for the type', () {
      // A missing row is indistinguishable from one the data source dropped
      // as unreadable, so this must not assert a consent that was never
      // established -- it resolves exactly as a failed fetch does.
      test('falls closed to indeterminate with no prior acceptance', () async {
        remoteDataSource.publishedVersionsToReturn = [];

        final status = await resolver.resolve(
          type: type,
          acceptedVersion: null,
        );

        expect(status, const ConsentIndeterminate());
        expect(status.gatesAccess, isTrue);
      });

      test('falls back to unverified with a prior acceptance', () async {
        remoteDataSource.publishedVersionsToReturn = [];

        final status = await resolver.resolve(type: type, acceptedVersion: 2);

        expect(status, const ConsentUnverified(2));
        expect(status.gatesAccess, isFalse);
      });

      test('does not resolve to ConsentSatisfied', () async {
        // The regression this whole fix exists for: a dropped/absent row
        // must never compare as satisfied against every acceptance on file.
        remoteDataSource.publishedVersionsToReturn = [];

        final status = await resolver.resolve(
          type: type,
          acceptedVersion: null,
        );

        expect(status, isNot(isA<ConsentSatisfied>()));
      });
    });

    group('when the server publishes a matching row', () {
      test(
        'resolves via ConsentStatus.resolve, unaffected by this fix',
        () async {
          remoteDataSource.publishedVersionsToReturn = [published(version: 3)];

          final status = await resolver.resolve(type: type, acceptedVersion: 3);

          expect(status, const ConsentSatisfied(3));
        },
      );

      test('reports outdated when the accepted version trails', () async {
        remoteDataSource.publishedVersionsToReturn = [published(version: 3)];

        final status = await resolver.resolve(type: type, acceptedVersion: 2);

        expect(status, isA<ConsentOutdated>());
        expect(status.gatesAccess, isTrue);
      });

      test('ignores a published row for a different type', () async {
        remoteDataSource.publishedVersionsToReturn = [
          ConsentVersionDto(
            id: 'analytics-1',
            consentType: ConsentType.analytics,
            version: 1,
            documentUrl: 'https://example.com/analytics/v1',
            publishedAt: DateTime.utc(2026, 8, 11),
          ),
        ];

        final status = await resolver.resolve(
          type: type,
          acceptedVersion: null,
        );

        expect(status, const ConsentIndeterminate());
      });
    });

    group('when the fetch throws', () {
      test('falls closed to indeterminate with no prior acceptance', () async {
        remoteDataSource.error = Exception('offline');

        final status = await resolver.resolve(
          type: type,
          acceptedVersion: null,
        );

        expect(status, const ConsentIndeterminate());
        expect(status.gatesAccess, isTrue);
      });

      test('falls back to unverified with a prior acceptance', () async {
        remoteDataSource.error = Exception('offline');

        final status = await resolver.resolve(type: type, acceptedVersion: 1);

        expect(status, const ConsentUnverified(1));
        expect(status.gatesAccess, isFalse);
      });
    });
  });
}
