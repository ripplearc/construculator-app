// coverage:ignore-file

part of 'consent_gate_bloc.dart';

/// Things that can change what the consent gate shows.
sealed class ConsentGateEvent extends Equatable {
  const ConsentGateEvent();

  @override
  List<Object?> get props => [];
}

/// The gate page was opened.
///
/// Resolves from local data first so the answer is immediate, then kicks off
/// background verification.
class ConsentGateStarted extends ConsentGateEvent {
  const ConsentGateStarted();
}

/// The user pressed accept.
class ConsentGateAccepted extends ConsentGateEvent {
  /// The version being accepted.
  ///
  /// Carried on the event rather than read from state at write time, so the
  /// record names the version the user was actually shown.
  final ConsentVersion version;

  const ConsentGateAccepted(this.version);

  @override
  List<Object?> get props => [version];
}

/// The user asked to try again after a failed write or a failed verification.
class ConsentGateRetryRequested extends ConsentGateEvent {
  const ConsentGateRetryRequested();
}

// ignore: unused_element -- constructed and handled once ConsentGateBloc lands.
class _ConsentGateStatusChanged extends ConsentGateEvent {
  final Either<Failure, ConsentStatus> result;

  const _ConsentGateStatusChanged(this.result);

  @override
  List<Object?> get props => [result];
}
