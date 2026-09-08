import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentStatus', () {
    final publishedVersion = ConsentVersion(
      id: 'version-2',
      consentType: ConsentType.termsAndPrivacy,
      version: 2,
      documentUrl: 'https://example.com/terms/v2',
      publishedAt: DateTime.utc(2026, 8, 11),
    );

    bool gates(ConsentStatus status) => status.gatesAccess;

    test('lets a current acceptance through', () {
      expect(gates(const ConsentSatisfied(2)), isFalse);
    });

    test('lets an unverifiable check through when an acceptance exists', () {
      // The single leniency in the design: the user demonstrably accepted at
      // some point and nothing observed since contradicts it.
      expect(gates(const ConsentUnverified(2)), isFalse);
    });

    test('blocks when a newer version has been published', () {
      expect(
        gates(
          ConsentOutdated(acceptedVersion: 1, requiredVersion: publishedVersion),
        ),
        isTrue,
      );
    });

    test('blocks when nothing has ever been accepted', () {
      expect(gates(ConsentNeverGiven(publishedVersion)), isTrue);
    });

    test('blocks when the requirement could not be established', () {
      // Nothing to fall back on and no document to name, so neither letting
      // the user through nor prompting them would be honest.
      expect(
        gates(const ConsentIndeterminate(ConsentType.termsAndPrivacy)),
        isTrue,
      );
    });

    test('distinguishes an unverified check from a satisfied one', () {
      // Both are ungated, but they must stay distinguishable: only one of them
      // means the version was actually confirmed.
      expect(const ConsentUnverified(2), isNot(const ConsentSatisfied(2)));
    });

    test('compares unverified checks by the version being trusted', () {
      // Same type on both sides, so Equatable actually reads props here. The
      // fail-open state must not lose the version it is vouching for.
      expect(const ConsentUnverified(2), const ConsentUnverified(2));
      expect(const ConsentUnverified(1), isNot(const ConsentUnverified(2)));
    });

    test('keeps an unresolved check tied to the document it was for', () {
      // The two documents version independently, so an unresolved check on one
      // must not read as an unresolved check on the other -- a caller
      // resolving both would otherwise get an indistinguishable value.
      expect(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
      );
      expect(
        const ConsentIndeterminate(ConsentType.termsAndPrivacy),
        isNot(const ConsentIndeterminate(ConsentType.analytics)),
      );
    });

    test('compares outdated statuses by accepted and required version', () {
      expect(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: publishedVersion),
        ConsentOutdated(acceptedVersion: 1, requiredVersion: publishedVersion),
      );
      expect(
        ConsentOutdated(acceptedVersion: 1, requiredVersion: publishedVersion),
        isNot(
          ConsentOutdated(
            acceptedVersion: 0,
            requiredVersion: publishedVersion,
          ),
        ),
      );
    });

    group('resolve', () {
      test('is never given when there is no accepted version', () {
        final status = ConsentStatus.resolve(
          acceptedVersion: null,
          published: publishedVersion,
        );

        expect(status, ConsentNeverGiven(publishedVersion));
      });

      test('is satisfied at the exact boundary where accepted equals published', () {
        final status = ConsentStatus.resolve(
          acceptedVersion: 2,
          published: publishedVersion,
        );

        expect(status, const ConsentSatisfied(2));
      });

      test('is satisfied when the accepted version exceeds the published one', () {
        final status = ConsentStatus.resolve(
          acceptedVersion: 3,
          published: publishedVersion,
        );

        expect(status, const ConsentSatisfied(3));
      });

      test('is outdated just below the boundary', () {
        final status = ConsentStatus.resolve(
          acceptedVersion: 1,
          published: publishedVersion,
        );

        expect(
          status,
          ConsentOutdated(acceptedVersion: 1, requiredVersion: publishedVersion),
        );
      });

      test('names the published version as the requirement when outdated', () {
        final status = ConsentStatus.resolve(
              acceptedVersion: 1,
              published: publishedVersion,
            )
            as ConsentOutdated;

        expect(status.requiredVersion, publishedVersion);
      });
    });
  });
}
