import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/data/repositories/consent_repository_impl.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_local_consent_data_source.dart';
import 'package:construculator/libraries/consent/testing/fake_remote_consent_data_source.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/supabase/testing/fake_supabase_wrapper.dart';
import 'package:construculator/libraries/time/testing/fake_clock_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const type = ConsentType.termsAndPrivacy;
  const userId = 'user-1';

  late FakeLocalConsentDataSource local;
  late FakeRemoteConsentDataSource remote;
  late FakeSupabaseWrapper supabase;
  late FakeClockImpl clock;
  late ConsentRepositoryImpl repository;

  ConsentVersionDto version(int number) => ConsentVersionDto(
    id: 'version-$number',
    consentType: type,
    version: number,
    documentUrl: 'https://example.com/terms/v$number',
    publishedAt: DateTime.utc(2026, 8, 11),
  );

  UserConsentDto record(int number, ConsentAction action) => UserConsentDto.stored(
    id: 'record-$number',
    userId: userId,
    consentType: type,
    version: number,
    action: action,
    recordedAt: DateTime.utc(2026, 8, 11),
  );

  setUp(() {
    local = FakeLocalConsentDataSource();
    remote = FakeRemoteConsentDataSource();
    clock = FakeClockImpl();
    supabase = FakeSupabaseWrapper(clock: clock);
    supabase.setInternalUserId(userId);

    repository = ConsentRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      supabaseWrapper: supabase,
      clock: clock,
    );
  });

  tearDown(() => local.dispose());

  group('getCachedConsentStatus', () {
    test(
      'is satisfied when the accepted version matches the published one',
      () async {
        local.publishedVersions[type] = version(2);
        await local.seedLatestConsent(record(2, ConsentAction.accepted));

        final result = await repository.getCachedConsentStatus(type);

        expect(result, const ConsentSatisfied(2));
      },
    );

    test(
      'is satisfied when the accepted version exceeds the published one',
      () async {
        // Can happen after a rollback on the server. The user has agreed to at
        // least what is being asked, so there is nothing to prompt for.
        local.publishedVersions[type] = version(2);
        await local.seedLatestConsent(record(3, ConsentAction.accepted));

        final result = await repository.getCachedConsentStatus(type);

        expect(result, const ConsentSatisfied(3));
      },
    );

    test('is outdated when a newer version has been published', () async {
      local.publishedVersions[type] = version(3);
      await local.seedLatestConsent(record(2, ConsentAction.accepted));

      final status = await repository.getCachedConsentStatus(type);

      expect(status, isA<ConsentOutdated>());
      expect((status as ConsentOutdated).acceptedVersion, 2);
      expect(status.requiredVersion.version, 3);
    });

    test('has never been given when no record exists', () async {
      local.publishedVersions[type] = version(1);

      final status = await repository.getCachedConsentStatus(type);

      expect(status, isA<ConsentNeverGiven>());
      expect((status as ConsentNeverGiven).requiredVersion.version, 1);
    });

    test(
      'has never been given when the newest record is a withdrawal',
      () async {
        // A withdrawal leaves the user in the same position as someone who never
        // accepted — not in the position of someone still on the withdrawn
        // version.
        local.publishedVersions[type] = version(2);
        await local.seedLatestConsent(record(2, ConsentAction.withdrawn));

        final status = await repository.getCachedConsentStatus(type);

        expect(status, isA<ConsentNeverGiven>());
      },
    );

    test('is indeterminate when the requirement has not arrived', () async {
      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentIndeterminate(type));
    });

    test(
      'resolves a failed published-version read to a status, never a failure',
      () async {
        // A read that failed establishes nothing, which is the same position as
        // a clean read that found no requirement. Returning a Left here would
        // let the guard treat a broken read as better evidence than a working
        // one.
        local.publishedVersionReadError = const FormatException('corrupt row');

        final result = await repository.getCachedConsentStatus(type);

        expect(result, const ConsentIndeterminate(type));
      },
    );

    test(
      'resolves a failed user-consent read to a status, never a failure',
      () async {
        // The two local reads are separate failure sites; the published-version
        // read succeeding must not mask this one failing.
        local.publishedVersions[type] = version(1);
        local.latestConsentReadError = const FormatException('corrupt row');

        final result = await repository.getCachedConsentStatus(type);

        expect(result, const ConsentIndeterminate(type));
      },
    );

    test('does not gate a signed-out user', () async {
      supabase.setInternalUserId(null);

      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentSatisfied(0));
    });
  });

  group('verifyPublishedVersion', () {
    test('is outdated when the server publishes a newer version', () async {
      await local.seedLatestConsent(record(1, ConsentAction.accepted));
      remote.publishedVersionsToReturn = [version(2)];

      final status = await repository.verifyPublishedVersion(type);

      expect(status, isA<ConsentOutdated>());
      expect((status as ConsentOutdated).requiredVersion.version, 2);
    });

    test('ignores versions published for other consent types', () async {
      await local.seedLatestConsent(record(1, ConsentAction.accepted));
      remote.publishedVersionsToReturn = [
        ConsentVersionDto(
          id: 'analytics-9',
          consentType: ConsentType.analytics,
          version: 9,
          documentUrl: 'https://example.com/analytics/v9',
          publishedAt: DateTime.utc(2026, 8, 11),
        ),
      ];

      final status = await repository.verifyPublishedVersion(type);

      // An analytics version must never gate terms & privacy. It also cannot
      // confirm them: the server said nothing about this type, so the prior
      // acceptance stands unverified rather than being reported as checked.
      expect(status, const ConsentUnverified(1));
    });

    test(
      'is indeterminate when nothing is published and nothing was accepted',
      () async {
        remote.publishedVersionsToReturn = [];

        final status = await repository.verifyPublishedVersion(type);

        // Nothing to fall back on and no requirement established, so the
        // requirement cannot be asserted as met. Treating an absent row as
        // satisfied is what let a dropped or corrupt row un-gate the user.
        expect(status, const ConsentIndeterminate(type));
      },
    );

    // Retry behaviour itself belongs to RetryingRemoteConsentDataSource and is
    // covered in its own test. What matters here is only what the repository
    // does with the outcome.
    test(
      'falls open to unverified when the fetch fails with an acceptance on file',
      () async {
        // The single leniency in the design, and it is safe because the user
        // demonstrably accepted at some point.
        await local.seedLatestConsent(record(2, ConsentAction.accepted));
        remote.error = const SocketException('offline');

        final result = await repository.verifyPublishedVersion(type);

        expect(result, const ConsentUnverified(2));
      },
    );

    test(
      'falls closed to indeterminate when the fetch fails with nothing on file',
      () async {
        // Nothing to fall back on and no document to name, so neither letting
        // the user through nor prompting them would be honest.
        remote.error = const SocketException('offline');

        final result = await repository.verifyPublishedVersion(type);

        expect(result, const ConsentIndeterminate(type));
      },
    );

    test('treats a withdrawn record as nothing on file when failing', () async {
      await local.seedLatestConsent(record(2, ConsentAction.withdrawn));
      remote.error = const SocketException('offline');

      final result = await repository.verifyPublishedVersion(type);

      expect(result, const ConsentIndeterminate(type));
    });

    test(
      'calls the remote source once, leaving retries to the decorator',
      () async {
        await local.seedLatestConsent(record(2, ConsentAction.accepted));
        remote.error = const FormatException('bad payload');

        await repository.verifyPublishedVersion(type);

        expect(remote.callCount, 1);
      },
    );

    test('does not gate a signed-out user', () async {
      supabase.setInternalUserId(null);

      final result = await repository.verifyPublishedVersion(type);

      expect(result, const ConsentSatisfied(0));
      expect(remote.callCount, 0);
    });
  });

  group('recordAcceptance', () {
    test('appends an acceptance stamped from the clock', () async {
      clock.set(DateTime.utc(2026, 8, 13, 9, 30));

      final result = await repository.recordAcceptance(
        consentType: type,
        version: 4,
      );

      expect(result.isRight(), isTrue);
      expect(local.insertedRecords.single.action, ConsentAction.accepted);
      expect(local.insertedRecords.single.version, 4);
      expect(
        local.insertedRecords.single.recordedAt,
        DateTime.utc(2026, 8, 13, 9, 30),
      );
    });

    test('surfaces a write failure rather than swallowing it', () async {
      // Swallowing this would leave the user believing they had consented when
      // no record exists.
      local.writeError = const SocketException('offline');

      final result = await repository.recordAcceptance(
        consentType: type,
        version: 4,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.connectionError),
      );
    });

    test('maps a timeout to a timeout failure', () async {
      local.writeError = TimeoutException('slow');

      final result = await repository.recordAcceptance(
        consentType: type,
        version: 4,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.timeoutError),
      );
    });

    test(
      'fails when there is no signed-in user to attribute the record to',
      () async {
        supabase.setInternalUserId(null);

        final result = await repository.recordAcceptance(
          consentType: type,
          version: 4,
        );

        expect(
          result.getLeftOrNull(),
          const ConsentFailure(errorType: ConsentErrorType.authenticationError),
        );
      },
    );
  });

  group('recordWithdrawal', () {
    test('appends a withdrawal carrying the version being revoked', () async {
      await local.seedLatestConsent(record(3, ConsentAction.accepted));

      final result = await repository.recordWithdrawal(consentType: type);

      expect(result.isRight(), isTrue);
      expect(local.insertedRecords.single.action, ConsentAction.withdrawn);
      expect(
        local.insertedRecords.single.version,
        3,
        reason: 'the audit row must name what was revoked',
      );
    });

    test('leaves the user gated afterwards', () async {
      local.publishedVersions[type] = version(3);
      await local.seedLatestConsent(record(3, ConsentAction.accepted));

      await repository.recordWithdrawal(consentType: type);
      final status = await repository.getCachedConsentStatus(type);

      expect(status, isA<ConsentNeverGiven>());
    });

    test(
      'records version zero when there is nothing on file to revoke',
      () async {
        // Keeps the audit row readable rather than naming a version that was
        // never accepted.
        final result = await repository.recordWithdrawal(consentType: type);

        expect(result.isRight(), isTrue);
        expect(local.insertedRecords.single.version, 0);
      },
    );

    test(
      'records version zero when the version being withdrawn cannot be read',
      () async {
        // A broken read here must not fail the withdrawal outright -- it
        // falls back to the same "nothing on file" version as a clean read
        // that found no prior acceptance.
        local.latestConsentReadError = const FormatException('corrupt row');

        final result = await repository.recordWithdrawal(consentType: type);

        expect(result.isRight(), isTrue);
        expect(local.insertedRecords.single.version, 0);
      },
    );
  });

  group('watchConsentStatus', () {
    test('emits a new status when the consent record changes', () async {
      local.publishedVersions[type] = version(2);

      // A single continuous subscription plus emitsInOrder, rather than
      // pumpEventQueue as a barrier: the expectation is set up before the
      // write happens, so it cannot race the subscription regardless of how
      // many turns the underlying generator takes to attach (see #542/#554
      // -- pumpEventQueue papered over exactly that same race).
      final statuses = repository.watchConsentStatus(type);
      final expectation = expectLater(
        statuses,
        emitsInOrder([isA<ConsentNeverGiven>(), const ConsentSatisfied(2)]),
      );

      await local.seedLatestConsent(record(2, ConsentAction.accepted));
      await expectation;
    });

    test(
      'resolves a watch failure to unverified when a prior acceptance exists',
      () async {
        // A broken published-version read on a tick that DID deliver a real
        // acceptance must not discard it: the accepted version is known
        // here, so this falls back to it (ConsentUnverified) rather than
        // blanket-gating a fully-consented user (ConsentIndeterminate). The
        // acceptance and the error are both set up before subscribing, so
        // the very first tick already carries both.
        await local.seedLatestConsent(record(1, ConsentAction.accepted));
        local.publishedVersionReadError = const FormatException('corrupt row');

        final statuses = repository.watchConsentStatus(type);

        await expectLater(statuses, emits(const ConsentUnverified(1)));
      },
    );

    test(
      'resolves a watch failure to indeterminate with no prior acceptance',
      () async {
        local.publishedVersionReadError = const FormatException('corrupt row');

        final statuses = repository.watchConsentStatus(type);

        await expectLater(statuses, emits(const ConsentIndeterminate(type)));
      },
    );

    test('resolves a genuine watch stream error to indeterminate, not just a '
        'per-tick read failure', () async {
      // Distinct from the read-failure cases above: this fails the tick
      // itself (watchLatestUserConsent's own stream), which the try/catch
      // inside asyncMap never sees -- only the outer transform's
      // handleError reaches it, and there the accepted version genuinely
      // is unknown, even though a real acceptance IS on file.
      await local.seedLatestConsent(record(1, ConsentAction.accepted));
      local.watchError = const FormatException('stream broke');

      final statuses = repository.watchConsentStatus(type);

      await expectLater(statuses, emits(const ConsentIndeterminate(type)));
    });
  });

  group('dispose', () {
    test('closes the underlying watch stream', () async {
      final statuses = repository.watchConsentStatus(type);

      // The first emission is the initial subscribe tick; dispose() must
      // close the stream after it rather than leaving it open forever.
      final done = expectLater(statuses, emitsInOrder([anything, emitsDone]));
      repository.dispose();
      await done;
    });
  });
}
