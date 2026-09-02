import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentVersionDto', () {
    Map<String, dynamic> buildJson({
      Object? id = 'version-1',
      Object? consentType = 'terms_and_privacy',
      Object? version = 2,
      Object? documentUrl = 'https://example.com/terms/v2',
      Object? publishedAt = '2026-08-11T00:00:00.000Z',
    }) => {
      'id': id,
      'consent_type': consentType,
      'version': version,
      'document_url': documentUrl,
      'published_at': publishedAt,
    };

    group('fromJson', () {
      test('reads a complete row', () {
        final dto = ConsentVersionDto.fromJson(buildJson());

        expect(
          dto,
          ConsentVersionDto(
            id: 'version-1',
            consentType: ConsentType.termsAndPrivacy,
            version: 2,
            documentUrl: 'https://example.com/terms/v2',
            publishedAt: DateTime.utc(2026, 8, 11),
          ),
        );
      });

      test('reads the analytics consent type', () {
        // Both wire values, so a mapping hardcoded to one is visible here.
        final dto = ConsentVersionDto.fromJson(
          buildJson(consentType: 'analytics'),
        );

        expect(dto.consentType, ConsentType.analytics);
      });

      test('rejects version zero', () {
        // The case the strictness exists for. A zero compares as satisfied
        // against every acceptance on file, so it would silently mark every
        // user current -- the outcome the class doc says throwing prevents.
        expect(
          () => ConsentVersionDto.fromJson(buildJson(version: 0)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a negative version', () {
        expect(
          () => ConsentVersionDto.fromJson(buildJson(version: -1)),
          throwsA(isA<FormatException>()),
        );
      });

      test('reads a version delivered as a numeric string', () {
        // Whether a local store hands numbers back as text is not this DTO's
        // to assume, and the repo parses numeric columns permissively.
        final dto = ConsentVersionDto.fromJson(buildJson(version: '3'));

        expect(dto.version, 3);
      });

      test('reads a version delivered as a double', () {
        final dto = ConsentVersionDto.fromJson(buildJson(version: 3.0));

        expect(dto.version, 3);
      });

      test('rejects a version that is not a number at all', () {
        expect(
          () => ConsentVersionDto.fromJson(buildJson(version: 'two')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a fractional version rather than truncating it', () {
        // A silent truncation (2.7 -> 2) would compare against the wrong
        // acceptance; the backend guarantees an integer column, so this is
        // defensive, but it must fail loudly rather than round.
        expect(
          () => ConsentVersionDto.fromJson(buildJson(version: 2.7)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects an unrecognised consent type', () {
        expect(
          () => ConsentVersionDto.fromJson(
            buildJson(consentType: 'marketing_emails'),
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects an empty document url', () {
        // Nothing to present means a consent page with nothing to review.
        expect(
          () => ConsentVersionDto.fromJson(buildJson(documentUrl: '')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a document url that is not a usable link', () {
        // 'n/a' passes a non-empty check and then fails at tap time, on the
        // one screen the user has no back affordance to leave.
        expect(
          () => ConsentVersionDto.fromJson(buildJson(documentUrl: 'n/a')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a document url with a non-web scheme', () {
        expect(
          () => ConsentVersionDto.fromJson(
            buildJson(documentUrl: 'ftp://example.com/terms'),
          ),
          throwsA(isA<FormatException>()),
        );
      });

      test('accepts a plain http document url', () {
        final dto = ConsentVersionDto.fromJson(
          buildJson(documentUrl: 'http://example.com/terms'),
        );

        expect(dto.documentUrl, 'http://example.com/terms');
      });

      test('rejects a non-string document url', () {
        expect(
          () => ConsentVersionDto.fromJson(buildJson(documentUrl: 42)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a non-string id', () {
        expect(
          () => ConsentVersionDto.fromJson(buildJson(id: 7)),
          throwsA(isA<FormatException>()),
        );
      });

      test('names the field that could not be read', () {
        // The only symptom of this path is the app blocking at launch, so the
        // field name is what makes it diagnosable from a breadcrumb.
        expect(
          () => ConsentVersionDto.fromJson(buildJson(documentUrl: '')),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('document_url'),
            ),
          ),
        );
      });
    });

    group('publishedAt', () {
      test('reads a timestamp string', () {
        final dto = ConsentVersionDto.fromJson(
          buildJson(publishedAt: '2026-08-11T00:00:00.000Z'),
        );

        expect(dto.publishedAt, DateTime.utc(2026, 8, 11));
      });

      test('passes a DateTime through unchanged', () {
        final dto = ConsentVersionDto.fromJson(
          buildJson(publishedAt: DateTime.utc(2026, 8, 12)),
        );

        expect(dto.publishedAt, DateTime.utc(2026, 8, 12));
      });

      test('falls back to the epoch when the string is unparseable', () {
        // Audit metadata, not gate input, so an unreadable value must not
        // fail a row the gate can otherwise decide on.
        final dto = ConsentVersionDto.fromJson(buildJson(publishedAt: 'soon'));

        expect(
          dto.publishedAt,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      });

      test('falls back to the epoch when the value is missing', () {
        final dto = ConsentVersionDto.fromJson(buildJson(publishedAt: null));

        expect(
          dto.publishedAt,
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        );
      });

      test('stamps the fallback in UTC', () {
        // publishedAt is in props, so a local epoch would compare differently
        // depending on the machine running the test.
        final dto = ConsentVersionDto.fromJson(buildJson(publishedAt: null));

        expect(dto.publishedAt.isUtc, isTrue);
      });
    });

    group('tryFromJson', () {
      test('reads a valid row', () {
        final dto = ConsentVersionDto.tryFromJson(buildJson());

        expect(dto, isNotNull);
        expect(dto!.version, 2);
      });

      test('returns null instead of throwing on an unreadable row', () {
        // Lets a batch reader drop one bad row without discarding the good
        // ones beside it.
        expect(
          ConsentVersionDto.tryFromJson(buildJson(consentType: 'marketing')),
          isNull,
        );
      });
    });

    test('toDomain carries every field to the entity', () {
      final entity = ConsentVersionDto.fromJson(buildJson()).toDomain();

      expect(
        entity,
        ConsentVersion(
          id: 'version-1',
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
          documentUrl: 'https://example.com/terms/v2',
          publishedAt: DateTime.utc(2026, 8, 11),
        ),
      );
    });

    group('Equatable', () {
      test('treats rows with identical fields as equal', () {
        expect(
          ConsentVersionDto.fromJson(buildJson()),
          ConsentVersionDto.fromJson(buildJson()),
        );
      });

      test('distinguishes rows by every field it declares', () {
        final base = ConsentVersionDto.fromJson(buildJson());

        final variants = <String, Map<String, dynamic>>{
          'id': buildJson(id: 'version-2'),
          'consentType': buildJson(consentType: 'analytics'),
          'version': buildJson(version: 3),
          'documentUrl': buildJson(documentUrl: 'https://example.com/other'),
          'publishedAt': buildJson(publishedAt: '2026-08-12T00:00:00.000Z'),
        };

        variants.forEach((field, json) {
          expect(
            base,
            isNot(ConsentVersionDto.fromJson(json)),
            reason: '$field must participate in equality',
          );
        });
      });
    });
  });
}
