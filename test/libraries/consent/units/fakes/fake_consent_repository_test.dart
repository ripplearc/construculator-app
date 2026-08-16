import 'dart:async';

import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_repository.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeConsentRepository repository;

  setUp(() => repository = FakeConsentRepository());

  const type = ConsentType.termsAndPrivacy;

  group('reads', () {
    test('resolves the configured cached status', () async {
      repository.cachedStatusToReturn = const ConsentIndeterminate();

      expect(
        await repository.getCachedConsentStatus(type),
        const ConsentIndeterminate(),
      );
    });

    test('resolves the configured verification status', () async {
      repository.verifiedStatusToReturn = const ConsentUnverified(4);

      expect(
        await repository.verifyPublishedVersion(type),
        const ConsentUnverified(4),
      );
    });

    test('records the type every read was asked about', () async {
      await repository.getCachedConsentStatus(ConsentType.analytics);
      await repository.verifyPublishedVersion(type);
      repository.watchConsentStatus(ConsentType.analytics);

      expect(repository.cachedStatusRequests, [ConsentType.analytics]);
      expect(repository.verificationRequests, [type]);
      expect(repository.watchRequests, [ConsentType.analytics]);
    });

    test('prefers the stream factory over the fixed stream', () async {
      repository.statusStreamToReturn = Stream.value(
        const ConsentIndeterminate(),
      );
      repository.statusStreamFactory = () =>
          Stream.value(const ConsentSatisfied(9));

      expect(
        await repository.watchConsentStatus(type).first,
        const ConsentSatisfied(9),
      );
    });
  });

  group('writes', () {
    test('echoes the acceptance back as a record', () async {
      final result = await repository.recordAcceptance(
        consentType: type,
        version: 5,
      );
      final record = result.getRightOrNull()!;

      expect(record.consentType, type);
      expect(record.version, 5);
      expect(record.action, ConsentAction.accepted);
      expect(repository.recordedAcceptances, [
        (consentType: type, version: 5),
      ]);
    });

    test('names the accepted version on the withdrawal that revokes it', () async {
      // The entity documents a withdrawal's version as the one being revoked,
      // which is what makes the audit trail readable after the fact.
      await repository.recordAcceptance(consentType: type, version: 7);

      final result = await repository.recordWithdrawal(consentType: type);

      expect(result.getRightOrNull()!.version, 7);
      expect(result.getRightOrNull()!.action, ConsentAction.withdrawn);
    });

    test('withdraws version zero when nothing is on file', () async {
      final result = await repository.recordWithdrawal(consentType: type);

      expect(result.getRightOrNull()!.version, 0);
    });

    test('keeps the two documents independent when withdrawing', () async {
      await repository.recordAcceptance(consentType: type, version: 3);
      await repository.recordAcceptance(
        consentType: ConsentType.analytics,
        version: 8,
      );

      final result = await repository.recordWithdrawal(
        consentType: ConsentType.analytics,
      );

      expect(result.getRightOrNull()!.version, 8);
    });

    test('stamps records with a fixed UTC timestamp', () async {
      // Not machine-local: UserConsent compares recordedAt, so a local
      // timestamp would pass on one timezone and fail on another.
      final result = await repository.recordAcceptance(
        consentType: type,
        version: 1,
      );

      expect(result.getRightOrNull()!.recordedAt, DateTime.utc(1970));
      expect(result.getRightOrNull()!.recordedAt.isUtc, isTrue);
    });

    test('fails only the write it was configured to fail', () async {
      // Accepting succeeds while withdrawing fails: the matrix the settings
      // withdrawal tile has to handle.
      const failure = ConsentFailure(errorType: ConsentErrorType.unexpectedError);
      repository.withdrawalResultToReturn = const Left(failure);

      final accepted = await repository.recordAcceptance(
        consentType: type,
        version: 2,
      );
      final withdrawn = await repository.recordWithdrawal(consentType: type);

      expect(accepted.isRight(), isTrue);
      expect(withdrawn.getLeftOrNull(), failure);
    });

    test('holds a write in flight until its completer resolves', () async {
      final inFlight = Completer<void>();
      repository.acceptanceCompleter = inFlight;

      var settled = false;
      unawaited(
        repository
            .recordAcceptance(consentType: type, version: 1)
            .then((_) => settled = true),
      );
      await pumpEventQueue();

      expect(settled, isFalse, reason: 'the write must not resolve yet');

      inFlight.complete();
      await pumpEventQueue();

      expect(settled, isTrue);
    });
  });

  test('counts disposals', () {
    repository.dispose();
    repository.dispose();

    expect(repository.disposeCallCount, 2);
  });

  test('reset returns every field to its initial state', () async {
    // Consumers bind this as a singleton, so a module built in setUpAll shares
    // one instance across a whole file.
    await repository.getCachedConsentStatus(type);
    await repository.verifyPublishedVersion(type);
    repository.watchConsentStatus(type);
    await repository.recordAcceptance(consentType: type, version: 3);
    await repository.recordWithdrawal(consentType: type);
    repository.dispose();
    // Set after the calls: a pending completer would block the writes above.
    repository
      ..cachedStatusToReturn = const ConsentIndeterminate()
      ..verifiedStatusToReturn = const ConsentIndeterminate()
      ..statusStreamFactory = Stream<ConsentStatus>.empty
      ..acceptanceResultToReturn = const Left(
        ConsentFailure(errorType: ConsentErrorType.unexpectedError),
      )
      ..withdrawalResultToReturn = const Left(
        ConsentFailure(errorType: ConsentErrorType.unexpectedError),
      )
      ..acceptanceCompleter = Completer<void>()
      ..withdrawalCompleter = Completer<void>();

    repository.reset();

    expect(repository.cachedStatusToReturn, const ConsentSatisfied(1));
    expect(repository.verifiedStatusToReturn, const ConsentSatisfied(1));
    expect(repository.statusStreamFactory, isNull);
    expect(repository.acceptanceResultToReturn, isNull);
    expect(repository.withdrawalResultToReturn, isNull);
    expect(repository.acceptanceCompleter, isNull);
    expect(repository.withdrawalCompleter, isNull);
    expect(repository.disposeCallCount, 0);
    expect(repository.cachedStatusRequests, isEmpty);
    expect(repository.watchRequests, isEmpty);
    expect(repository.verificationRequests, isEmpty);
    expect(repository.recordedAcceptances, isEmpty);
    expect(repository.recordedWithdrawals, isEmpty);
    expect(await repository.watchConsentStatus(type).isEmpty, isTrue);
  });

  test('forgets accepted versions on reset', () async {
    await repository.recordAcceptance(consentType: type, version: 6);

    repository.reset();
    final result = await repository.recordWithdrawal(consentType: type);

    expect(result.getRightOrNull()!.version, 0);
  });
}
