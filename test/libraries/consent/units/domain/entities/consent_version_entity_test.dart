import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentVersion', () {
    final publishedAt = DateTime.utc(2026, 8, 11);

    ConsentVersion buildVersion({
      String id = 'version-1',
      ConsentType consentType = ConsentType.termsAndPrivacy,
      int version = 2,
      String documentUrl = 'https://example.com/terms/v2',
      DateTime? published,
    }) {
      var resolvedPublishedAt = publishedAt;
      if (published != null) {
        resolvedPublishedAt = published;
      }
      return ConsentVersion(
        id: id,
        consentType: consentType,
        version: version,
        documentUrl: documentUrl,
        publishedAt: resolvedPublishedAt,
      );
    }

    test('treats versions with identical fields as equal', () {
      expect(buildVersion(), buildVersion());
    });

    test('distinguishes published versions of the same document', () {
      // The comparison the gate exists to make: a newer publication must not
      // compare equal to the one the user already accepted.
      expect(buildVersion(version: 2), isNot(buildVersion(version: 3)));
    });

    test('distinguishes the two documents at the same version number', () {
      // Each type versions independently, so v2 of the terms and v2 of the
      // analytics policy are unrelated publications.
      expect(
        buildVersion(consentType: ConsentType.termsAndPrivacy),
        isNot(buildVersion(consentType: ConsentType.analytics)),
      );
    });

    test('distinguishes versions pointing at different documents', () {
      expect(
        buildVersion(documentUrl: 'https://example.com/terms/v2'),
        isNot(buildVersion(documentUrl: 'https://example.com/terms/v2-eu')),
      );
    });

    test('keeps the persisted row fields in equality', () {
      // Neither field is branched on by the gate, but both round-trip through
      // ConsentVersionDto, so equality has to cover them for a version read
      // back from the store to compare equal to the one written.
      expect(buildVersion(id: 'version-1'), isNot(buildVersion(id: 'version-2')));
      expect(
        buildVersion(published: DateTime.utc(2026, 8, 11)),
        isNot(buildVersion(published: DateTime.utc(2026, 8, 12))),
      );
    });

    test('exposes every field in props', () {
      final version = buildVersion();

      expect(version.props, [
        version.id,
        version.consentType,
        version.version,
        version.documentUrl,
        version.publishedAt,
      ]);
    });
  });
}
