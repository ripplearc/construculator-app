import 'package:construculator/libraries/consent/data/models/consent_wire_values.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsentTypeWireValue', () {
    test('maps each type to its column value', () {
      expect(ConsentType.termsAndPrivacy.toJson(), 'terms_and_privacy');
      expect(ConsentType.analytics.toJson(), 'analytics');
    });

    test('reads each column value back to its type', () {
      expect(
        ConsentTypeWireValue.fromJson('terms_and_privacy'),
        ConsentType.termsAndPrivacy,
      );
      expect(
        ConsentTypeWireValue.fromJson('analytics'),
        ConsentType.analytics,
      );
    });

    test('round-trips every declared type', () {
      // Catches a value added to the enum without a wire mapping, which would
      // otherwise surface only as a dropped row against a live server.
      for (final type in ConsentType.values) {
        expect(
          ConsentTypeWireValue.fromJson(type.toJson()),
          type,
          reason: '$type must survive a round trip',
        );
      }
    });

    test('returns null for an unrecognised value', () {
      // Guessing would attach a consent record to the wrong document.
      expect(ConsentTypeWireValue.fromJson('marketing_emails'), isNull);
      expect(ConsentTypeWireValue.fromJson(null), isNull);
      expect(ConsentTypeWireValue.fromJson(3), isNull);
    });
  });

  group('ConsentActionWireValue', () {
    test('maps each action to its column value', () {
      expect(ConsentAction.accepted.toJson(), 'accepted');
      expect(ConsentAction.withdrawn.toJson(), 'withdrawn');
    });

    test('reads each column value back to its action', () {
      expect(
        ConsentActionWireValue.fromJson('accepted'),
        ConsentAction.accepted,
      );
      expect(
        ConsentActionWireValue.fromJson('withdrawn'),
        ConsentAction.withdrawn,
      );
    });

    test('round-trips every declared action', () {
      for (final action in ConsentAction.values) {
        expect(
          ConsentActionWireValue.fromJson(action.toJson()),
          action,
          reason: '$action must survive a round trip',
        );
      }
    });

    test('returns null rather than defaulting to accepted', () {
      // An unreadable action must never be read as consent never given.
      expect(ConsentActionWireValue.fromJson('revoked'), isNull);
      expect(ConsentActionWireValue.fromJson(null), isNull);
    });
  });

  group('parseTimestampOrEpoch', () {
    test('passes a DateTime through unchanged', () {
      expect(
        parseTimestampOrEpoch(DateTime.utc(2026, 8, 11)),
        DateTime.utc(2026, 8, 11),
      );
    });

    test('parses a timestamp string', () {
      expect(
        parseTimestampOrEpoch('2026-08-11T00:00:00.000Z'),
        DateTime.utc(2026, 8, 11),
      );
    });

    test('falls back to the UTC epoch on an unparseable string', () {
      final parsed = parseTimestampOrEpoch('not a date');

      expect(parsed, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(parsed.isUtc, isTrue);
    });

    test('falls back to the UTC epoch on a missing value', () {
      final parsed = parseTimestampOrEpoch(null);

      expect(parsed, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
      expect(parsed.isUtc, isTrue);
    });
  });

  group('parseTimestamp', () {
    test('passes a DateTime through unchanged', () {
      expect(parseTimestamp(DateTime.utc(2026, 8, 11)), DateTime.utc(2026, 8, 11));
    });

    test('parses a timestamp string', () {
      expect(
        parseTimestamp('2026-08-11T00:00:00.000Z'),
        DateTime.utc(2026, 8, 11),
      );
    });

    test('returns null rather than defaulting on an unparseable string', () {
      // Unlike parseTimestampOrEpoch: this reader has no safe default to
      // fall back to, and leaves that decision to the caller.
      expect(parseTimestamp('not a date'), isNull);
    });

    test('returns null on a missing value', () {
      expect(parseTimestamp(null), isNull);
    });
  });

  group('parseVersion', () {
    test('accepts an int', () {
      expect(parseVersion(3), 3);
    });

    test('accepts a double', () {
      expect(parseVersion(3.0), 3);
    });

    test('accepts a numeric string', () {
      expect(parseVersion('3'), 3);
    });

    test('returns null for a non-numeric string', () {
      expect(parseVersion('three'), isNull);
    });

    test('returns null for a missing value', () {
      expect(parseVersion(null), isNull);
    });
  });
}
