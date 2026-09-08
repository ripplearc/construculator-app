import 'package:construculator/libraries/consent/data/consent_recorder.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_local_consent_data_source.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  group('ConsentRecorder', () {
    late FakeLocalConsentDataSource dataSource;
    late FakeClockImpl clock;
    late ConsentRecorder recorder;

    setUp(() {
      dataSource = FakeLocalConsentDataSource();
      clock = FakeClockImpl(DateTime.utc(2026, 8, 18, 12));
      recorder = ConsentRecorder(dataSource, clock);
    });

    test('fails without writing when there is no signed-in user', () async {
      final result = await recorder.record(
        userId: null,
        consentType: ConsentType.termsAndPrivacy,
        version: 4,
        action: ConsentAction.accepted,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.authenticationError),
      );
      expect(dataSource.insertedRecords, isEmpty);
    });

    test('records an acceptance stamped with the current time', () async {
      final result = await recorder.record(
        userId: 'user-1',
        consentType: ConsentType.termsAndPrivacy,
        version: 4,
        action: ConsentAction.accepted,
      );

      expect(dataSource.insertedRecords, hasLength(1));
      final written = dataSource.insertedRecords.single;
      expect(written.id, isNull);
      expect(written.userId, 'user-1');
      expect(written.consentType, ConsentType.termsAndPrivacy);
      expect(written.version, 4);
      expect(written.action, ConsentAction.accepted);
      expect(written.recordedAt, clock.now());

      expect(result.isRight(), isTrue);
      final stored = result.getRightOrNull();
      expect(stored!.id, isNotEmpty);
      expect(stored.userId, 'user-1');
      expect(stored.version, 4);
      expect(stored.action, ConsentAction.accepted);

      // The row the store wrote back, not one rebuilt from the arguments:
      // only the store can supply the id, so a recorder that echoed its own
      // input would be indistinguishable from this without the comparison.
      final onFile = await dataSource.fetchLatestUserConsent(
        'user-1',
        ConsentType.termsAndPrivacy,
      );
      expect(stored, onFile!.toDomain());
    });

    test('records a withdrawal the same way as an acceptance', () async {
      await recorder.record(
        userId: 'user-1',
        consentType: ConsentType.analytics,
        version: 2,
        action: ConsentAction.withdrawn,
      );

      expect(dataSource.insertedRecords.single.action, ConsentAction.withdrawn);
    });

    test('maps a permission-denied write failure', () async {
      dataSource.writeError = const supabase.PostgrestException(
        message: 'new row violates row-level security policy',
        code: '42501',
      );

      final result = await recorder.record(
        userId: 'user-1',
        consentType: ConsentType.termsAndPrivacy,
        version: 4,
        action: ConsentAction.accepted,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.permissionDenied),
      );
    });

    test('maps an expired session on write to authenticationError', () async {
      dataSource.writeError = const supabase.AuthException(
        'invalid claim: missing sub',
      );

      final result = await recorder.record(
        userId: 'user-1',
        consentType: ConsentType.termsAndPrivacy,
        version: 4,
        action: ConsentAction.accepted,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.authenticationError),
      );
    });

    test('maps anything unrecognised to unexpectedError', () async {
      dataSource.writeError = StateError('bad state');

      final result = await recorder.record(
        userId: 'user-1',
        consentType: ConsentType.termsAndPrivacy,
        version: 4,
        action: ConsentAction.accepted,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.unexpectedError),
      );
    });
  });
}
