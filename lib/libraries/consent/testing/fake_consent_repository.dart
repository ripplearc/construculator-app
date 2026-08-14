import 'dart:async';

import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// A fake implementation of [ConsentRepository] for testing purposes.
///
/// Lives in the consent library so every consumer — the route guard, the gate
/// BLoC, the signup flow — can import it rather than rolling a bespoke private
/// fake per test. Configure the `*ToReturn` fields to drive a scenario; read
/// the `*Requests` and `recorded*` lists to assert what the subject asked for.
/// Call [reset] between tests when one instance outlives a single test.
class FakeConsentRepository implements ConsentRepository {
  /// The version the default statuses report as accepted.
  static const _defaultAcceptedVersion = 1;

  /// A record's timestamp, fixed and in UTC so it cannot vary by machine.
  static final _recordedAt = DateTime.utc(1970);

  /// The status [getCachedConsentStatus] resolves to.
  ///
  /// Defaults to satisfied so tests that do not care about the gate are not
  /// forced to configure it. The corollary is that a passing gate assertion
  /// against an unconfigured fake proves nothing — a subject that never calls
  /// the repository, or calls it for the wrong [ConsentType], reads the same
  /// as one that genuinely passed. Tests that are *about* the gate must set
  /// this explicitly.
  ConsentStatus cachedStatusToReturn = const ConsentSatisfied(
    _defaultAcceptedVersion,
  );

  /// The status [verifyPublishedVersion] resolves to.
  ConsentStatus verifiedStatusToReturn = const ConsentSatisfied(
    _defaultAcceptedVersion,
  );

  /// The stream [watchConsentStatus] returns.
  Stream<ConsentStatus> statusStreamToReturn = const Stream.empty();

  /// Optional stream builder used by [watchConsentStatus] to create a fresh
  /// stream per call.
  ///
  /// Useful in tests that trigger re-subscription, where a
  /// single-subscription stream cannot be listened to twice.
  Stream<ConsentStatus> Function()? statusStreamFactory;

  /// The result [recordAcceptance] resolves to.
  ///
  /// Left `null` to have the write succeed with a record echoing the request.
  Either<Failure, UserConsent>? acceptanceResultToReturn;

  /// The result [recordWithdrawal] resolves to.
  ///
  /// Separate from [acceptanceResultToReturn] so a test can express "accepting
  /// succeeds, withdrawing fails", which is the matrix the settings withdrawal
  /// tile has to handle.
  Either<Failure, UserConsent>? withdrawalResultToReturn;

  /// When set, [recordAcceptance] does not complete until this completer does.
  ///
  /// Lets a test observe the in-flight submitting state, which otherwise
  /// resolves within the same frame it is entered.
  Completer<void>? acceptanceCompleter;

  /// When set, [recordWithdrawal] does not complete until this completer does.
  Completer<void>? withdrawalCompleter;

  /// How many times [dispose] has been called.
  ///
  /// Lets a test assert that whoever owns this repository released it, which
  /// is the omission the interface's `dispose` exists to make visible.
  int disposeCallCount = 0;

  /// The consent types passed to [getCachedConsentStatus], in call order.
  final List<ConsentType> cachedStatusRequests = [];

  /// The consent types passed to [watchConsentStatus], in call order.
  final List<ConsentType> watchRequests = [];

  /// The consent types passed to [verifyPublishedVersion], in call order.
  final List<ConsentType> verificationRequests = [];

  /// The `(type, version)` pairs passed to [recordAcceptance], in call order.
  final List<({ConsentType consentType, int version})> recordedAcceptances = [];

  /// The consent types passed to [recordWithdrawal], in call order.
  final List<ConsentType> recordedWithdrawals = [];

  // The newest accepted version per type, so a withdrawal can name what it
  // revokes instead of a number the real repository never produces.
  final Map<ConsentType, int> _acceptedVersions = {};

  /// Restores every field to its initial state.
  ///
  /// Consumers bind this as a singleton, and a module built in `setUpAll`
  /// shares one instance across every test in the file — without this, the
  /// recording lists grow unbounded and one test's scenario leaks into the
  /// next.
  void reset() {
    cachedStatusToReturn = const ConsentSatisfied(_defaultAcceptedVersion);
    verifiedStatusToReturn = const ConsentSatisfied(_defaultAcceptedVersion);
    statusStreamToReturn = const Stream.empty();
    statusStreamFactory = null;
    acceptanceResultToReturn = null;
    withdrawalResultToReturn = null;
    acceptanceCompleter = null;
    withdrawalCompleter = null;
    disposeCallCount = 0;
    cachedStatusRequests.clear();
    watchRequests.clear();
    verificationRequests.clear();
    recordedAcceptances.clear();
    recordedWithdrawals.clear();
    _acceptedVersions.clear();
  }

  @override
  Future<ConsentStatus> getCachedConsentStatus(ConsentType type) async {
    cachedStatusRequests.add(type);
    return cachedStatusToReturn;
  }

  @override
  Stream<ConsentStatus> watchConsentStatus(ConsentType type) {
    watchRequests.add(type);
    return statusStreamFactory?.call() ?? statusStreamToReturn;
  }

  @override
  Future<ConsentStatus> verifyPublishedVersion(ConsentType type) async {
    verificationRequests.add(type);
    return verifiedStatusToReturn;
  }

  @override
  Future<Either<Failure, UserConsent>> recordAcceptance({
    required ConsentType consentType,
    required int version,
  }) async {
    final record = _record(consentType, version, ConsentAction.accepted);
    recordedAcceptances.add((consentType: consentType, version: version));
    _acceptedVersions[consentType] = version;
    await acceptanceCompleter?.future;
    return acceptanceResultToReturn ?? Right(record);
  }

  @override
  Future<Either<Failure, UserConsent>> recordWithdrawal({
    required ConsentType consentType,
  }) async {
    // The version being revoked, as the real repository reads it back from the
    // record on file. Zero when there is nothing to revoke.
    final version = _acceptedVersions[consentType] ?? 0;
    final record = _record(consentType, version, ConsentAction.withdrawn);
    recordedWithdrawals.add(consentType);
    _acceptedVersions.remove(consentType);
    await withdrawalCompleter?.future;
    return withdrawalResultToReturn ?? Right(record);
  }

  @override
  void dispose() => disposeCallCount++;

  // Ids are assigned before the call is recorded, so the first record is
  // fake-consent-0 and ids line up with the recording lists' indices.
  UserConsent _record(ConsentType type, int version, ConsentAction action) =>
      UserConsent(
        id: 'fake-consent-'
            '${recordedAcceptances.length + recordedWithdrawals.length}',
        userId: 'fake-user',
        consentType: type,
        version: version,
        action: action,
        recordedAt: _recordedAt,
      );
}
