import 'dart:async';

import 'package:construculator/libraries/consent/domain/entities/consent_status_entity.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
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
class ConsentGateBloc extends Bloc<ConsentGateEvent, ConsentGateState> {
  final CheckConsentStatusUseCase _checkConsentStatusUseCase;
  final WatchConsentStatusUseCase _watchConsentStatusUseCase;
  final VerifyConsentStatusUseCase _verifyConsentStatusUseCase;
  final RecordConsentUseCase _recordConsentUseCase;

  /// The gate only ever governs terms & privacy. Analytics consent is read
  /// elsewhere and never blocks the app.
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
    // to the consent history should not churn the UI.
    _subscription ??= _watchConsentStatusUseCase(_params).distinct().listen(
      (status) => add(_ConsentGateStatusChanged(status)),
    );

    // Phase three. The local answer is already on screen, so confirming it
    // against the server blocks nothing; only a confirmed mismatch interrupts.
    // This is also the only path that can report ConsentUnverified, which is
    // how a failed check with a prior acceptance on file fails open.
    final verified = await _verifyConsentStatusUseCase(_params);
    if (state is! ConsentGateSubmitting) emit(_stateFor(verified));
  }

  void _onStatusChanged(
    _ConsentGateStatusChanged event,
    Emitter<ConsentGateState> emit,
  ) {
    // A write in flight must not be clobbered by a stream tick, or the button
    // would flicker back out of its loading state mid-submit.
    if (state is ConsentGateSubmitting) return;

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

  Future<void> _onRetryRequested(
    ConsentGateRetryRequested event,
    Emitter<ConsentGateState> emit,
  ) async {
    emit(const ConsentGateChecking());
    add(const ConsentGateStarted());
  }

  // Maps a resolved status onto what the page should show.
  ConsentGateState _stateFor(ConsentStatus status) => switch (status) {
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
    ConsentIndeterminate() => const ConsentGateUnavailable(),
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
