import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

final _recordedAt = DateTime.utc(2026, 8, 11);

UserConsent _buildConsent({
  String id = 'consent-1',
  String userId = 'user-1',
  ConsentType consentType = ConsentType.termsAndPrivacy,
  ConsentAction action = ConsentAction.accepted,
  int version = 3,
  DateTime? recorded,
  String? appVersion,
  String? platform,
}) => UserConsent(
  id: id,
  userId: userId,
  consentType: consentType,
  version: version,
  action: action,
  recordedAt: recorded ?? _recordedAt,
  appVersion: appVersion,
  platform: platform,
);

void main() {
  group('UserConsent', () {
    test('treats records with identical fields as equal', () {
      expect(_buildConsent(), _buildConsent());
    });

    test('distinguishes an acceptance from a withdrawal of the same version', () {
      expect(
        _buildConsent(action: ConsentAction.accepted),
        isNot(_buildConsent(action: ConsentAction.withdrawn)),
      );
    });

    // Every declared field must reach props. The entity's only behaviour is
    // its identity, so an omission here is invisible to every other assertion
    // in the module -- including the DTO round-trip in #537, which maps all
    // eight fields.
    final distinguishingFields = <String, UserConsent Function()>{
      'id': () => _buildConsent(id: 'consent-2'),
      'userId': () => _buildConsent(userId: 'user-2'),
      'consentType': () => _buildConsent(consentType: ConsentType.analytics),
      'version': () => _buildConsent(version: 4),
      'action': () => _buildConsent(action: ConsentAction.withdrawn),
      'recordedAt': () => _buildConsent(recorded: DateTime.utc(2026, 8, 12)),
      'appVersion': () => _buildConsent(appVersion: '1.2.0'),
      'platform': () => _buildConsent(platform: 'android'),
    };

    distinguishingFields.forEach((field, build) {
      test('distinguishes records differing only by $field', () {
        expect(_buildConsent(), isNot(build()));
      });
    });

    test('leaves audit metadata null when not supplied', () {
      final consent = _buildConsent();

      expect(consent.appVersion, isNull);
      expect(consent.platform, isNull);
    });
  });
}
