import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:equatable/equatable.dart';

/// Outcome of comparing the published consent version against the user's
/// accepted one.
///
/// Sealed so that every `switch` over a status is exhaustive: adding a case
/// becomes a compile error at each call site rather than a silently unhandled
/// branch. Given what these branches decide — whether a user reaches the app
/// at all — a missed case must not be something the compiler tolerates.
///
/// [gatesAccess] states which of them block. The split is not simply "errors
/// gate": it turns on whether there is a prior acceptance to fall back on, and
/// on the type, since only terms and privacy ever gates. See
/// [ConsentUnverified] and [ConsentIndeterminate].
sealed class ConsentStatus extends Equatable {
  const ConsentStatus();

  /// Whether this outcome blocks the user from reaching the app.
  ///
  /// The single definition of the gating policy, for the same reason [resolve]
  /// lives here: a second implementation that disagreed would gate users
  /// differently depending on which path reached it. The route guard and the
  /// tests both read this rather than restating the mapping.
  ///
  /// Type-aware: only [ConsentType.termsAndPrivacy] gates the app shell. An
  /// [ConsentType.analytics] outcome never does, whatever its status — a stale
  /// or missing analytics consent disables capture, it does not lock anyone
  /// out of a calculator. Every gating status already names its type, so the
  /// check needs nothing beyond what the status carries.
  bool get gatesAccess => switch (this) {
    ConsentSatisfied() || ConsentUnverified() => false,
    ConsentOutdated(:final requiredVersion) ||
    ConsentNeverGiven(
      :final requiredVersion,
    ) => _gatesShell(requiredVersion.consentType),
    ConsentIndeterminate(:final consentType) ||
    ConsentUserUnidentified(:final consentType) => _gatesShell(consentType),
  };

  static bool _gatesShell(ConsentType type) =>
      type == ConsentType.termsAndPrivacy;

  /// Resolves the gate outcome for [acceptedVersion] against [published].
  ///
  /// [acceptedVersion] is null when there is no acceptance on file — either
  /// none was ever given, or the newest record is a withdrawal, which leaves
  /// the user in exactly the same position as someone who never accepted.
  ///
  /// Both arguments must describe the same [ConsentType]. The two documents
  /// version independently, so comparing an analytics acceptance against a
  /// published terms version would un-gate the app on a consent the user never
  /// gave for that document. Callers resolve one type at a time.
  ///
  /// Lives on the status rather than in the repository because this *is* the
  /// definition of what these states mean. Every caller has to agree on it,
  /// and a second implementation that disagreed would gate users differently
  /// depending on which path reached it.
  ///
  /// Note this never returns [ConsentUnverified] or [ConsentIndeterminate]:
  /// both describe a requirement that could not be established, so there is no
  /// [published] to compare against and the caller resolves them directly.
  static ConsentStatus resolve({
    required int? acceptedVersion,
    required ConsentVersion published,
  }) {
    if (acceptedVersion == null) return ConsentNeverGiven(published);

    return acceptedVersion >= published.version
        ? ConsentSatisfied(acceptedVersion)
        : ConsentOutdated(
            acceptedVersion: acceptedVersion,
            requiredVersion: published,
          );
  }
}

/// The accepted version is at least the published version. Ungated.
class ConsentSatisfied extends ConsentStatus {
  /// The version the user has on file. Always a real acceptance, traced to a
  /// published row: a session the repository cannot identify reports
  /// [ConsentUserUnidentified] instead.
  final int acceptedVersion;

  const ConsentSatisfied(this.acceptedVersion);

  @override
  List<Object?> get props => [acceptedVersion];
}

/// A newer version has been published than the one the user accepted. Gated
/// for terms and privacy (see [gatesAccess]).
///
/// The only path that blocks a returning user, and it requires a *successfully
/// fetched* published version strictly greater than the accepted one — never
/// an inference drawn from a failed check.
class ConsentOutdated extends ConsentStatus {
  /// The superseded version the user has on file.
  final int acceptedVersion;

  /// The version they now need to accept, and the document to show them.
  final ConsentVersion requiredVersion;

  const ConsentOutdated({
    required this.acceptedVersion,
    required this.requiredVersion,
  });

  @override
  List<Object?> get props => [acceptedVersion, requiredVersion];
}

/// No acceptance on record — a cold install, cleared data, or a prior
/// withdrawal. Gated for terms and privacy (see [gatesAccess]).
class ConsentNeverGiven extends ConsentStatus {
  /// The version to present for acceptance.
  final ConsentVersion requiredVersion;

  const ConsentNeverGiven(this.requiredVersion);

  @override
  List<Object?> get props => [requiredVersion];
}

/// The published version could not be established, but the user has a prior
/// acceptance on record. **Ungated.**
///
/// A success-shaped value, not a failure — and that is the whole safety
/// property of this design. Distinguishing "we know consent is stale" from "we
/// could not check" is what stops a flaky network from being handled by the
/// same branch as a genuinely outdated version.
///
/// Failing open is defensible here precisely because of what the acceptance
/// guarantees: the user demonstrably agreed to [acceptedVersion] at some
/// point, and nothing observed since contradicts it. The worst case is running
/// under a superseded version for a few sessions until connectivity returns —
/// proportionate, and far better than bricking the app on a site with no
/// signal. The check simply retries on the next launch.
class ConsentUnverified extends ConsentStatus {
  /// The last known-good version on file, which is what is being trusted.
  final int acceptedVersion;

  const ConsentUnverified(this.acceptedVersion);

  @override
  List<Object?> get props => [acceptedVersion];
}

/// The requirement could not be established at all, and there is no prior
/// acceptance to fall back on. **Gated** for terms and privacy, with a retry
/// screen (see [gatesAccess]).
///
/// The deliberate exception to the leniency of [ConsentUnverified], and the
/// two must never be collapsed. Failing open requires something to fall back
/// on. With no acceptance on record there is no such evidence, and the client
/// additionally holds no version number and no document URL — so letting the
/// user through would mean running with no consent at all, and showing a
/// consent page would mean asking them to agree to a document the app cannot
/// name. Blocking with a retry affordance is the only honest option.
///
/// Rare in practice: reaching the gate requires a signed-in session, and
/// signing in requires the network, so consent data has almost always arrived
/// by the time the guard runs. It occurs when connectivity drops between
/// authentication and the first consent sync.
class ConsentIndeterminate extends ConsentStatus {
  /// Which document failed to resolve.
  ///
  /// Omitting the version and the URL is justified — neither is known — but
  /// *which* document was being checked always is: the caller asked about one
  /// type. Without it a caller resolving both, such as CA-964's analytics gate
  /// alongside the terms gate, receives an indistinguishable value for either.
  final ConsentType consentType;

  const ConsentIndeterminate(this.consentType);

  @override
  List<Object?> get props => [consentType];
}

/// The session is signed in but the repository cannot tell whose it is.
/// **Gated** for terms and privacy, with a retry screen (see [gatesAccess]).
///
/// `AuthGuard` passing does not rule this out: it tests the auth session,
/// while the internal user id comes from a separate JWT claim. A stale token
/// or a refresh race leaves a signed-in session without that claim, and it is
/// most likely for a brand-new signup, whose token is minted before the
/// profile exists.
///
/// Its own state rather than [ConsentSatisfied] carrying a synthetic version,
/// so every exhaustive switch has to decide what it means. Read as an
/// acceptance it would silently un-gate a user whose consent was never
/// evaluated.
class ConsentUserUnidentified extends ConsentStatus {
  /// Which document was being checked when the user could not be identified.
  final ConsentType consentType;

  const ConsentUserUnidentified(this.consentType);

  @override
  List<Object?> get props => [consentType];
}
