import 'dart:async';

import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/consent/domain/repositories/consent_repository.dart';
import 'package:construculator/libraries/consent/domain/types/consent_types.dart';
import 'package:construculator/libraries/consent/domain/usecases/check_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/params/consent_usecase_params.dart';
import 'package:construculator/libraries/consent/domain/usecases/record_consent_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/verify_consent_status_usecase.dart';
import 'package:construculator/libraries/consent/domain/usecases/watch_consent_status_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'consent_gate_event.dart';
part 'consent_gate_state.dart';

/// Drives the consent gate page.
///
/// Runs the three startup phases described in the design: a local resolution
/// that answers immediately, a background verification that blocks nothing,
/// and — only on a confirmed mismatch — an interruption.
///
/// The BLoC decides nothing about consent itself. It maps a [ConsentStatus]
/// onto what the page shows; the statuses come from the repository, which owns
/// the comparison and every failure branch around it.
///
/// The gate only ever governs terms & privacy. Analytics consent is read
/// elsewhere and never blocks the app.
class ConsentGateBloc extends Bloc<ConsentGateEvent, ConsentGateState> {
  final CheckConsentStatusUseCase _checkConsentStatusUseCase;
  final WatchConsentStatusUseCase _watchConsentStatusUseCase;
  final VerifyConsentStatusUseCase _verifyConsentStatusUseCase;
  final RecordConsentUseCase _recordConsentUseCase;

  static const _params = ConsentStatusParams(
    consentType: ConsentType.termsAndPrivacy,
  );

  StreamSubscription<ConsentStatus>? _subscription;

  ConsentGateBloc({
    required this._checkConsentStatusUseCase,
    required this._watchConsentStatusUseCase,
    required this._verifyConsentStatusUseCase,
    required this._recordConsentUseCase,
  }) : super(const ConsentGateChecking()) {
    on<ConsentGateStarted>(_onStarted);
    on<ConsentGateAccepted>(_onAccepted);
    on<ConsentGateRetryRequested>(_onRetryRequested);
    on<_ConsentGateStatusChanged>(_onStatusChanged);
  }

  Future<void> _onStarted(
    ConsentGateStarted event,
    Emitter<ConsentGateState> emit,
  ) async {
    final result = await _checkConsentStatusUseCase(_params);
    emit(_stateFor(result));

    // Subscribed after the first resolution so a version published mid-session
    // re-gates the user without a restart. Distinct because an unrelated write
    // to the consent history should not churn the UI. Deliberately
    // once-per-bloc: a retry re-adds ConsentGateStarted without tearing this
    // down, since watchConsentStatus's handleError resolves a failed tick to
    // ConsentIndeterminate rather than closing the stream.
    _subscription ??= _watchConsentStatusUseCase(
      _params,
    ).distinct().listen((status) => add(_ConsentGateStatusChanged(status)));

    // Phase three. The local answer is already on screen, so confirming it
    // against the server blocks nothing; only a confirmed mismatch interrupts.
    // This is also the only path that can report ConsentUnverified, which is
    // how a failed check with a prior acceptance on file fails open.
    final beforeVerify = state;
    final verified = await _verifyConsentStatusUseCase(_params);

    // A verification started before the user accepted cannot speak to what
    // they accepted: the resolver reads the local acceptance before its
    // round trip (see ConsentRepositoryImpl.verifyPublishedVersion), so an
    // accept that both starts and finishes during this await is invisible to
    // it. Guarding only ConsentGateSubmitting protects the write itself but
    // not the window right after: a verify resolving from a pre-write
    // snapshot would silently overwrite the accept's outcome with a stale
    // result.
    //
    // Comparing against a snapshot taken before the await, rather than
    // switching on the current state's type, is deliberate: this phase's own
    // first emission a few lines up can equally leave state as
    // ConsentGateAllowed before verify ever starts (an ordinary cache hit,
    // no accept involved), and that legitimate case must still let a
    // verify-confirmed mismatch through. Only a state that changed *during*
    // this specific await -- i.e. a concurrent _onAccepted -- should block
    // it, which is what an equality check against the snapshot captures and
    // a type check on the current state cannot.
    //
    // Known limitation: a watch-stream tick landing in this same window also
    // changes state and trips this guard, so a genuine verify result can be
    // dropped alongside a stale one. Narrow in practice -- watch ticks only
    // fire on a real local row change -- and scoping the guard to
    // accept-completions specifically would need a generation counter rather
    // than a state snapshot.
    if (state != beforeVerify) return;
    emit(_stateFor(verified));
  }

  void _onStatusChanged(
    _ConsentGateStatusChanged event,
    Emitter<ConsentGateState> emit,
  ) {
    // A write in flight, or one that just failed, must not be clobbered by a
    // stream tick: Submitting guards the button from flickering out of its
    // loading state mid-submit, and SubmitFailed guards the inline error and
    // retry affordance from being silently swapped for a generic status.
    if (state case ConsentGateSubmitting() || ConsentGateSubmitFailed()) {
      return;
    }

    emit(_stateFor(event.status));
  }

  Future<void> _onAccepted(
    ConsentGateAccepted event,
    Emitter<ConsentGateState> emit,
  ) async {
    emit(ConsentGateSubmitting(event.version));

    final result = await _recordConsentUseCase(
      RecordConsentParams(
        consentType: _params.consentType,
        version: event.version.version,
      ),
    );

    emit(
      result.fold(
        // The user stays on the page. Letting them through on a failed write
        // would mean running with consent that was never recorded.
        (_) => ConsentGateSubmitFailed(event.version),
        // Offline is still success here: the write landed locally and will
        // upload later, so there is no reason to make the user wait.
        (_) => ConsentGateAllowed(event.version.version),
      ),
    );
  }

  void _onRetryRequested(
    ConsentGateRetryRequested _,
    Emitter<ConsentGateState> emit,
  ) {
    add(const ConsentGateStarted());
  }

  // Maps a resolved status onto what the page should show.
  ConsentGateState _stateFor(ConsentStatus status) => switch (status) {
    // The repository answers with this synthetic version when it cannot
    // identify the user, which is not an acceptance -- ConsentGuard blocks on
    // it for that reason. Mapping it to Allowed here would navigate straight
    // back to the shell, whose guard redirects here again: an unbreakable
    // loop for exactly the session the guard exists to catch. Unavailable is
    // the same dead end the guard leaves the user in, and its retry re-reads
    // the status, so a JWT that later carries the claim resolves normally.
    ConsentSatisfied(acceptedVersion: ConsentRepository.noUserVersion) =>
      const ConsentGateUnavailable(),
    ConsentSatisfied(:final acceptedVersion) => ConsentGateAllowed(
      acceptedVersion,
    ),
    ConsentUnverified(:final acceptedVersion) => ConsentGateUnverified(
      acceptedVersion,
    ),
    ConsentOutdated(:final requiredVersion) => ConsentGateBlocked(
      requiredVersion,
    ),
    ConsentNeverGiven(:final requiredVersion) => ConsentGateBlocked(
      requiredVersion,
    ),
    // The user is already standing on an acceptance. A status that only
    // means "could not establish the requirement" is not evidence against
    // it, so it degrades to the ungated fallback rather than revoking
    // access mid-session -- the watch stream and the verify phase can both
    // deliver this after the user was already resolved to Allowed/
    // Unverified, and neither knows the prior state the way this switch
    // does. Cold start (no prior state) keeps its original behaviour.
    ConsentIndeterminate() => switch (state) {
      ConsentGateAllowed(:final acceptedVersion) ||
      ConsentGateUnverified(
        :final acceptedVersion,
      ) => ConsentGateUnverified(acceptedVersion),
      _ => const ConsentGateUnavailable(),
    },
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
