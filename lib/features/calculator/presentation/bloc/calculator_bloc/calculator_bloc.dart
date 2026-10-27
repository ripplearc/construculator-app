import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

part 'calculator_event.dart';
part 'dependent_key_id.dart';
part 'calculator_state.dart';

/// Presses the keyboard's keys on the engine's tape and keeps the tape as
/// its state (UX Design Doc Sections 1.1, 1.3 and 4; CA-1087, S1a).
///
/// The bloc holds no arithmetic and no rule of its own: each event is one
/// call on [Tape], whose outcome is folded into the state — a changed tape
/// with its notice, or the same tape with the refusal. Nothing here reads a
/// store, the recents or the preferences repository; the System of units
/// toggle sets the tape's own preferences, so the tape and the keyboard
/// agree on one value. The engine's answers (the strip, the pills, the
/// equals-key label) are mapped in S1b (CA-1088).
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(CalculatorState.initial()) {
    on<CalculatorKeySelected>(_onKeySelected);
    on<CalculatorDigitPressed>(_onDigitPressed);
    on<CalculatorFractionPressed>(_onFractionPressed);
    on<CalculatorUnitSelected>(_onUnitSelected);
    on<CalculatorOperatorPressed>(_onOperatorPressed);
    on<CalculatorEqualsPressed>(_onEqualsPressed);
    on<CalculatorControlActioned>(_onControlActioned);
    on<CalculatorGroupSelected>(_onGroupSelected);
    on<CalculatorUnitSystemChanged>(_onUnitSystemChanged);
    on<CalculatorResetRequested>(_onResetRequested);
  }

  static const Map<String, Unit> _unitKeys = {
    'bf': Unit.boardFoot,
    'm': Unit.metre,
    'cm': Unit.centimetre,
    'mm': Unit.millimetre,
    'lbs': Unit.pound,
    'kg': Unit.kilogram,
    'ton': Unit.ton,
    'mton': Unit.metricTon,
  };

  void _onKeySelected(
    CalculatorKeySelected event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) {
    if (_unitKeys[event.id] case final unit?) return tape.pressUnit(unit);
    return tape.pressFunctionKey(event.id);
  });

  void _onDigitPressed(
    CalculatorDigitPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.typeDigit(event.digit));

  void _onFractionPressed(
    CalculatorFractionPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.typeFraction());

  void _onUnitSelected(
    CalculatorUnitSelected event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.pressUnit(event.unit));

  void _onOperatorPressed(
    CalculatorOperatorPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.pressOperator(event.operator));

  void _onEqualsPressed(
    CalculatorEqualsPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.pressEquals());

  void _onControlActioned(
    CalculatorControlActioned event,
    Emitter<CalculatorState> emit,
  ) {
    switch (event.action) {
      case ControlAction.delete:
        _press(emit, (tape) => tape.backspace());
      case ControlAction.clearAll:
        emit(_cleared());
      case ControlAction.paren:
        _press(emit, (tape) => tape.pressBracket());
      // A value coreui deprecated and never sends; CA-1195 deletes it.
      case _:
        break;
    }
  }

  void _onGroupSelected(
    CalculatorGroupSelected event,
    Emitter<CalculatorState> emit,
  ) => emit(state.copyWith(currentGroupIndex: event.groupIndex));

  void _onUnitSystemChanged(
    CalculatorUnitSystemChanged event,
    Emitter<CalculatorState> emit,
  ) {
    final system = switch (event.unitSystem) {
      UnitSystem.imperial => MeasurementSystem.imperial,
      UnitSystem.metric => MeasurementSystem.metric,
    };
    emit(
      state.copyWith(
        tape: state.tape.withPreferences(
          state.tape.preferences.copyWith(system: system),
        ),
      ),
    );
  }

  void _onResetRequested(
    CalculatorResetRequested event,
    Emitter<CalculatorState> emit,
  ) => emit(_cleared());

  void _press(
    Emitter<CalculatorState> emit,
    TapeOutcome Function(Tape tape) press,
  ) {
    switch (press(state.tape)) {
      case TapeChanged(:final tape, :final notice):
        emit(
          state.copyWith(tape: tape, notice: () => notice, refusal: () => null),
        );
      case final TapeOutcome refusal:
        emit(state.copyWith(notice: () => null, refusal: () => refusal));
    }
  }

  CalculatorState _cleared() => CalculatorState(
    tape: Tape(preferences: state.tape.preferences),
    currentGroupIndex: state.currentGroupIndex,
  );
}
