import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/user_consent_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/either/either.dart';
import 'package:construculator/libraries/errors/failures.dart';

/// Data access contract for versioned consent.
///
/// ## Why the read path never returns a [Failure]
///
/// Three of these five methods answer the question "may this user get into
/// the app?", and for those a `Left` would be actively harmful. The gate has to
/// distinguish *knowing* consent is stale from *being unable to check*, and it
/// has to treat a broken read no more leniently than a clean one. Both
/// distinctions live in [ConsentStatus], so the read methods resolve every
/// expected condition — timeouts, unreachable servers, unsynced tables, even a
/// failed local read — to a status, and their signatures say so by returning
/// one directly.
///
/// The write path is the exception and returns a real `Left`: if recording an
/// acceptance fails the user must be told and offered a retry, because
/// swallowing it would leave them believing they had consented when no record
/// exists. That asymmetry is the design, which is why it is visible in the
/// types rather than only in this prose.
abstract class ConsentRepository {
  /// The version reported when the gate does not apply to the session.
  ///
  /// A signed-out user has no consent record and nothing to be gated on, which
  /// is not an error and not an acceptance. Callers that key behaviour off
  /// [ConsentSatisfied] — analytics capture in particular — must establish
  /// that there is a signed-in user before reading this as consent given.
  static const noUserVersion = 0;

  /// Resolves the user's status for [type] from locally held data only.
  ///
  /// Never touches the network, so it completes fast enough to sit on the app
  /// start path — this is what the route guard calls. A failed local read
  /// resolves to [ConsentIndeterminate]: a read that failed establishes
  /// nothing, which is the same position as a clean read that found no
  /// requirement, so it must resolve the same way.
  ///
  /// Returns [ConsentSatisfied] carrying [noUserVersion] when no user is
  /// signed in.
  Future<ConsentStatus> getCachedConsentStatus(ConsentType type);

  /// Emits whenever the locally held consent data for [type] changes.
  ///
  /// Lets a version published while the app is open take effect on the next
  /// sync rather than the next cold start. Callers must cancel their
  /// subscription — see the stream lifecycle rule.
  ///
  /// The stream never emits an error and never terminates on failure. A tick
  /// that cannot be resolved is dropped and superseded by the next successful
  /// one, so a subscriber sees a gap rather than a broken subscription.
  Stream<ConsentStatus> watchConsentStatus(ConsentType type);

  /// Establishes the published version for [type] authoritatively.
  ///
  /// Goes straight to the server rather than reading locally held data, so a
  /// stalled sync cannot mask a newly published version. Does not give up on
  /// the first transient failure.
  ///
  /// On giving up, returns a status rather than raising, and which status
  /// depends entirely on whether there is a prior acceptance to fall back on:
  /// [ConsentUnverified] when there is one, [ConsentIndeterminate] when there
  /// is not. An unreachable server is an expected condition on a mobile
  /// network, not an error to surface.
  Future<ConsentStatus> verifyPublishedVersion(ConsentType type);

  /// Appends an acceptance record for [consentType] at [version].
  ///
  /// Completes without requiring network reachability, and the record is
  /// durable once it returns, so accepting while offline succeeds. Returns a
  /// `Left` if the record cannot be written — the caller must not treat a
  /// failed write as consent given.
  ///
  /// Implementations must source the record's timestamp from the injected
  /// `Clock` rather than `DateTime.now()`, so the write path stays
  /// deterministic under test.
  Future<Either<Failure, UserConsent>> recordAcceptance({
    required ConsentType consentType,
    required int version,
  });

  /// Appends a withdrawal record for [consentType].
  ///
  /// Appends rather than deleting the acceptance, which is what keeps the
  /// audit trail meaningful. Takes no version: it revokes whatever the user
  /// currently has on file, and the effective status becomes
  /// [ConsentNeverGiven].
  ///
  /// Timestamped from the injected `Clock`, as [recordAcceptance] is.
  Future<Either<Failure, UserConsent>> recordWithdrawal({
    required ConsentType consentType,
  });

  /// Releases any resources held by the repository.
  ///
  /// Implementations should cancel active subscriptions and close any
  /// internal controllers to avoid memory leaks.
  void dispose();
}
