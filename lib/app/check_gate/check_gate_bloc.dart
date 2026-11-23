import 'package:construculator/libraries/auth/check/check_state.dart';
import 'package:construculator/libraries/auth/check/interfaces/check_finished_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// An input to [CheckGateBloc].
sealed class CheckGateEvent {
  const CheckGateEvent();
}

/// The gate is on screen and should follow the check-finished state.
final class CheckGateStarted extends CheckGateEvent {
  /// Starts following the state.
  const CheckGateStarted();
}

/// What the gate shows.
sealed class CheckGateState extends Equatable {
  const CheckGateState();

  @override
  List<Object?> get props => const [];
}

/// The check has not finished, so a loading screen covers every screen.
final class CheckGateHolding extends CheckGateState {
  /// A gate that covers the screens.
  const CheckGateHolding();
}

/// The check finished, so the screens show.
final class CheckGateReleased extends CheckGateState {
  /// A gate that lets the screens show.
  const CheckGateReleased();
}

/// Tells the app shell whether the sign-in check has finished.
class CheckGateBloc extends Bloc<CheckGateEvent, CheckGateState> {
  final CheckFinishedState _checkFinishedState;

  /// A gate that follows [checkFinishedState], starting from its value.
  CheckGateBloc({required CheckFinishedState checkFinishedState})
    : _checkFinishedState = checkFinishedState,
      super(_gateFor(checkFinishedState.value)) {
    on<CheckGateStarted>(
      (event, emit) => emit.forEach<CheckState>(
        _checkFinishedState.changes,
        onData: _gateFor,
      ),
    );
  }

  // TODO: [CA-1497] Show the retry screen while blocked and the restart
  // screen when a restart is required.
  // https://ripplearc.youtrack.cloud/issue/CA-1497
  static CheckGateState _gateFor(CheckState checkState) => checkState.isFinished
      ? const CheckGateReleased()
      : const CheckGateHolding();
}
