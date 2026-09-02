import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserConsentDto', () {
    Map<String, dynamic> buildJson({
      Object? id = 'record-1',
      Object? userId = 'user-1',
      Object? consentType = 'terms_and_privacy',
      Object? version = 2,
      Object? action = 'accepted',
      Object? recordedAt = '2026-08-11T00:00:00.000Z',
      Object? appVersion = '1.0.0',
      Object? platform = 'ios',
    }) => {
      'id': id,
      'user_id': userId,
      'consent_type': consentType,
      'version': version,
      'action': action,
      'recorded_at': recordedAt,
      'app_version': appVersion,
      'platform': platform,
    };

    group('fromJson', () {
      test('reads a complete row', () {
        final dto = UserConsentDto.fromJson(buildJson());

        expect(
          dto,
          UserConsentDto.stored(
            id: 'record-1',
            userId: 'user-1',
            consentType: ConsentType.termsAndPrivacy,
            version: 2,
            action: ConsentAction.accepted,
            recordedAt: DateTime.utc(2026, 8, 11),
            appVersion: '1.0.0',
            platform: 'ios',
          ),
        );
      });

      test('reads the analytics consent type', () {
        final dto = UserConsentDto.fromJson(
          buildJson(consentType: 'analytics'),
        );

        expect(dto.consentType, ConsentType.analytics);
      });

      test('reads the withdrawn action', () {
        final dto = UserConsentDto.fromJson(buildJson(action: 'withdrawn'));

        expect(dto.action, ConsentAction.withdrawn);
      });

      test('reads a version delivered as a numeric string', () {
        final dto = UserConsentDto.fromJson(buildJson(version: '3'));

        expect(dto.version, 3);
      });

      test('rejects an unrecognised consent type', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(consentType: 'marketing')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects an unrecognised action', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(action: 'revoked')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects version zero', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(version: 0)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a negative version', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(version: -1)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a version that is not a number at all', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(version: 'two')),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a non-string id', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(id: 7)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a non-string user id', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(userId: 7)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects a missing recorded_at', () {
        // The case the strictness exists for. recordedAt orders the consent
        // history, and ConsentRepositoryImpl._effectiveAcceptedVersion reads
        // the newest record to decide the gate. A fallback to the epoch here
        // would sort a withdrawal with an unreadable recorded_at below the
        // acceptance it supersedes -- reading as consent the user revoked.
        expect(
          () => UserConsentDto.fromJson(buildJson(recordedAt: null)),
          throwsA(isA<FormatException>()),
        );
      });

      test('rejects an unparseable recorded_at', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(recordedAt: 'soon')),
          throwsA(isA<FormatException>()),
        );
      });

      test('names the field that could not be read', () {
        expect(
          () => UserConsentDto.fromJson(buildJson(recordedAt: 'soon')),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('recorded_at'),
            ),
          ),
        );
      });

      test('drops a non-string app_version to null rather than throwing', () {
        final dto = UserConsentDto.fromJson(buildJson(appVersion: 12));

        expect(dto.appVersion, isNull);
      });

      test('drops a non-string platform to null rather than throwing', () {
        final dto = UserConsentDto.fromJson(buildJson(platform: 12));

        expect(dto.platform, isNull);
      });

      test('leaves audit metadata null when absent', () {
        final dto = UserConsentDto.fromJson(
          buildJson(appVersion: null, platform: null),
        );

        expect(dto.appVersion, isNull);
        expect(dto.platform, isNull);
      });
    });

    group('toInsertJson', () {
      test('omits id', () {
        final json = UserConsentDto.fromJson(buildJson()).toInsertJson();

        expect(json.containsKey('id'), isFalse);
      });

      test('serializes recordedAt as a UTC ISO 8601 string', () {
        final local = DateTime(2026, 8, 11, 9);
        final dto = UserConsentDto.draft(
          userId: 'user-1',
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
          action: ConsentAction.accepted,
          recordedAt: local,
        );

        final serialized =
            dto.toInsertJson()['recorded_at'] as String;

        expect(serialized, local.toUtc().toIso8601String());
        expect(DateTime.parse(serialized).isUtc, isTrue);
      });

      test('omits absent audit metadata', () {
        final dto = UserConsentDto.draft(
          userId: 'user-1',
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
          action: ConsentAction.accepted,
          recordedAt: DateTime.utc(2026, 8, 11),
        );

        final json = dto.toInsertJson();

        expect(json.containsKey('app_version'), isFalse);
        expect(json.containsKey('platform'), isFalse);
      });

      test('includes audit metadata when present', () {
        final json = UserConsentDto.fromJson(buildJson()).toInsertJson();

        expect(json['app_version'], '1.0.0');
        expect(json['platform'], 'ios');
      });
    });

    group('toDomain', () {
      test('carries every field to the entity', () {
        final entity = UserConsentDto.fromJson(buildJson()).toDomain();

        expect(
          entity,
          UserConsent(
            id: 'record-1',
            userId: 'user-1',
            consentType: ConsentType.termsAndPrivacy,
            version: 2,
            action: ConsentAction.accepted,
            recordedAt: DateTime.utc(2026, 8, 11),
            appVersion: '1.0.0',
            platform: 'ios',
          ),
        );
      });

      test('throws on a draft record with no assigned id', () {
        final dto = UserConsentDto.draft(
          userId: 'user-1',
          consentType: ConsentType.termsAndPrivacy,
          version: 2,
          action: ConsentAction.accepted,
          recordedAt: DateTime.utc(2026, 8, 11),
        );

        expect(dto.toDomain, throwsA(isA<StateError>()));
      });
    });

    group('Equatable', () {
      test('treats rows with identical fields as equal', () {
        expect(
          UserConsentDto.fromJson(buildJson()),
          UserConsentDto.fromJson(buildJson()),
        );
      });

      test('distinguishes rows by every field it declares', () {
        final base = UserConsentDto.fromJson(buildJson());

        final variants = <String, Map<String, dynamic>>{
          'id': buildJson(id: 'record-2'),
          'userId': buildJson(userId: 'user-2'),
          'consentType': buildJson(consentType: 'analytics'),
          'version': buildJson(version: 3),
          'action': buildJson(action: 'withdrawn'),
          'recordedAt': buildJson(recordedAt: '2026-08-12T00:00:00.000Z'),
          'appVersion': buildJson(appVersion: '2.0.0'),
          'platform': buildJson(platform: 'android'),
        };

        variants.forEach((field, json) {
          expect(
            base,
            isNot(UserConsentDto.fromJson(json)),
            reason: '$field must participate in equality',
          );
        });
      });
    });
  });
}
