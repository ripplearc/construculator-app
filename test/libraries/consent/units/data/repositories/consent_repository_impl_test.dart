import 'dart:async';
import 'dart:io';

import 'package:construculator/libraries/consent/data/models/consent_version_dto.dart';
import 'package:construculator/libraries/consent/data/models/user_consent_dto.dart';
import 'package:construculator/libraries/consent/data/repositories/consent_repository_impl.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_error_type.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/testing/fake_consent_data_sources.dart';
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

  UserConsentDto record(int number, ConsentAction action) => UserConsentDto(
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
    test('is satisfied when the accepted version matches the published one', () async {
      local.publishedVersions[type] = version(2);
      local.latestConsents[type] = record(2, ConsentAction.accepted);

      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentSatisfied(2));
    });

    test('is satisfied when the accepted version exceeds the published one', () async {
      // Can happen after a rollback on the server. The user has agreed to at
      // least what is being asked, so there is nothing to prompt for.
      local.publishedVersions[type] = version(2);
      local.latestConsents[type] = record(3, ConsentAction.accepted);

      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentSatisfied(3));
    });

    test('is outdated when a newer version has been published', () async {
      local.publishedVersions[type] = version(3);
      local.latestConsents[type] = record(2, ConsentAction.accepted);

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

    test('has never been given when the newest record is a withdrawal', () async {
      // A withdrawal leaves the user in the same position as someone who never
      // accepted — not in the position of someone still on the withdrawn
      // version.
      local.publishedVersions[type] = version(2);
      local.latestConsents[type] = record(2, ConsentAction.withdrawn);

      final status = await repository.getCachedConsentStatus(type);

      expect(status, isA<ConsentNeverGiven>());
    });

    test('is indeterminate when the requirement has not arrived', () async {
      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentIndeterminate());
    });

    test('resolves a failed local read to a status, never a failure', () async {
      // A read that failed establishes nothing, which is the same position as
      // a clean read that found no requirement. Returning a Left here would
      // let the guard treat a broken read as better evidence than a working
      // one.
      local.readError = const FormatException('corrupt row');

      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentIndeterminate());
    });

    test('does not gate a signed-out user', () async {
      supabase.setInternalUserId(null);

      final result = await repository.getCachedConsentStatus(type);

      expect(result, const ConsentSatisfied(0));
    });
  });

  group('verifyPublishedVersion', () {
    test('is outdated when the server publishes a newer version', () async {
      local.latestConsents[type] = record(1, ConsentAction.accepted);
      remote.publishedVersions = [version(2)];

      final status = await repository.verifyPublishedVersion(type);

      expect(status, isA<ConsentOutdated>());
      expect((status as ConsentOutdated).requiredVersion.version, 2);
    });

    test('ignores versions published for other consent types', () async {
      local.latestConsents[type] = record(1, ConsentAction.accepted);
      remote.publishedVersions = [
        ConsentVersionDto(
          id: 'analytics-9',
          consentType: ConsentType.analytics,
          version: 9,
          documentUrl: 'https://example.com/analytics/v9',
          publishedAt: DateTime.utc(2026, 8, 11),
        ),
      ];

      final status = await repository.verifyPublishedVersion(type);

      // An analytics version must never gate terms & privacy.
      expect(status, const ConsentSatisfied(1));
    });

    test('is satisfied at version zero when nothing is published and nothing was accepted', () async {
      remote.publishedVersions = [];

      final status = await repository.verifyPublishedVersion(type);

      expect(status, const ConsentSatisfied(0));
    });

    // Retry behaviour itself belongs to RetryingRemoteConsentDataSource and is
    // covered in its own test. What matters here is only what the repository
    // does with the outcome.
    test('falls open to unverified when the fetch fails with an acceptance on file', () async {
      // The single leniency in the design, and it is safe because the user
      // demonstrably accepted at some point.
      local.latestConsents[type] = record(2, ConsentAction.accepted);
      remote.error = const SocketException('offline');

      final result = await repository.verifyPublishedVersion(type);

      expect(result, const ConsentUnverified(2));
    });

    test('falls closed to indeterminate when the fetch fails with nothing on file', () async {
      // Nothing to fall back on and no document to name, so neither letting
      // the user through nor prompting them would be honest.
      remote.error = const SocketException('offline');

      final result = await repository.verifyPublishedVersion(type);

      expect(result, const ConsentIndeterminate());
    });

    test('treats a withdrawn record as nothing on file when failing', () async {
      local.latestConsents[type] = record(2, ConsentAction.withdrawn);
      remote.error = const SocketException('offline');

      final result = await repository.verifyPublishedVersion(type);

      expect(result, const ConsentIndeterminate());
    });

    test('calls the remote source once, leaving retries to the decorator', () async {
      local.latestConsents[type] = record(2, ConsentAction.accepted);
      remote.error = const FormatException('bad payload');

      await repository.verifyPublishedVersion(type);

      expect(remote.callCount, 1);
    });

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

    test('fails when there is no signed-in user to attribute the record to', () async {
      supabase.setInternalUserId(null);

      final result = await repository.recordAcceptance(
        consentType: type,
        version: 4,
      );

      expect(
        result.getLeftOrNull(),
        const ConsentFailure(errorType: ConsentErrorType.authenticationError),
      );
    });
  });

  group('recordWithdrawal', () {
    test('appends a withdrawal carrying the version being revoked', () async {
      local.latestConsents[type] = record(3, ConsentAction.accepted);

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
      local.latestConsents[type] = record(3, ConsentAction.accepted);

      await repository.recordWithdrawal(consentType: type);
      final status = await repository.getCachedConsentStatus(type);

      expect(status, isA<ConsentNeverGiven>());
    });

    test('records version zero when there is nothing on file to revoke', () async {
      // Keeps the audit row readable rather than naming a version that was
      // never accepted.
      final result = await repository.recordWithdrawal(consentType: type);

      expect(result.isRight(), isTrue);
      expect(local.insertedRecords.single.version, 0);
    });
  });

  group('watchConsentStatus', () {
    test('emits a new status when the consent record changes', () async {
      local.publishedVersions[type] = version(2);

      final statuses = repository.watchConsentStatus(type);
      final emitted = expectLater(
        statuses,
        emitsInOrder([
          // The initial subscribe emission, from nothing on file yet.
          isA<ConsentNeverGiven>(),
          const ConsentSatisfied(2),
        ]),
      );

      local.emitLatestConsent(record(2, ConsentAction.accepted));
      await local.dispose();
      await emitted;
    });
  });
}
