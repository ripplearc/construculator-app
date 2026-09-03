// coverage:ignore-file

part of 'consent_gate_bloc.dart';

/// What the consent gate is currently showing.
///
/// Sealed so the page's switch is exhaustive. Most of these states render
/// nothing at all — the gate is designed to be invisible whenever it is not
/// actively blocking, so only four of the eight put anything on screen.
sealed class ConsentGateState extends Equatable {
  const ConsentGateState();

  @override
  List<Object?> get props => [];
}

/// Resolving the status from local data.
///
/// Renders nothing. It completes within a frame, so showing a spinner would
/// only produce a flash.
class ConsentGateChecking extends ConsentGateState {
  const ConsentGateChecking();
}

/// Consent is current. The user sees the app.
class ConsentGateAllowed extends ConsentGateState {
  /// The version the user stands on.
  final int acceptedVersion;

  const ConsentGateAllowed(this.acceptedVersion);

  @override
  List<Object?> get props => [acceptedVersion];
}

/// Background verification is in flight.
///
/// Renders nothing and blocks nothing — deliberately invisible.
class ConsentGateVerifying extends ConsentGateState {
  const ConsentGateVerifying();
}

/// Verification failed but a prior acceptance exists, so the user continues.
///
/// No error, no toast: nothing is wrong from the user's point of view and
/// there is no action for them to take.
class ConsentGateUnverified extends ConsentGateState {
  /// The last known-good version being trusted.
  final int acceptedVersion;

  const ConsentGateUnverified(this.acceptedVersion);

  @override
  List<Object?> get props => [acceptedVersion];
}

/// Blocked, with a document to present.
class ConsentGateBlocked extends ConsentGateState {
  /// The version the user must accept, carrying the document to link to.
  final ConsentVersion requiredVersion;

  const ConsentGateBlocked(this.requiredVersion);

  @override
  List<Object?> get props => [requiredVersion];
}

/// Writing the user's acceptance.
///
/// The accept button is replaced by a loading indicator; the page stays put.
class ConsentGateSubmitting extends ConsentGateState {
  /// The version being accepted, kept so the page can re-render the document
  /// links without flicker while the write is in flight.
  final ConsentVersion requiredVersion;

  const ConsentGateSubmitting(this.requiredVersion);

  @override
  List<Object?> get props => [requiredVersion];
}

/// The acceptance write failed.
///
/// The user stays on the page with an inline error and a retry. They are never
/// let through on a failed write.
class ConsentGateSubmitFailed extends ConsentGateState {
  /// The version still awaiting acceptance.
  final ConsentVersion requiredVersion;

  const ConsentGateSubmitFailed(this.requiredVersion);

  @override
  List<Object?> get props => [requiredVersion];
}

/// Blocked, with no acceptance on record and no reachable requirement.
///
/// Distinct from [ConsentGateBlocked] because there is no document to show:
/// the page renders a retry affordance rather than a consent prompt. Asking
/// someone to agree to a document the app cannot name would not be consent.
class ConsentGateUnavailable extends ConsentGateState {
  const ConsentGateUnavailable();
}
