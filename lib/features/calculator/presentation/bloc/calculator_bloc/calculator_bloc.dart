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
/// with its notice, or the same tape with the refusal. What it does know
/// is which key is which: the Unit group's keys press their unit, a trig
/// key and the D:M:S key press theirs, Pitch, Slope and Sides take a plain
/// number ([PlainNumberKeys]), and a unit under a length-only key (Section
/// 3, "Takes: A length") or under Slope goes to the tape with that said,
/// read off the chip being typed wherever it is. Nothing here reads a
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
    on<CalculatorActiveValueCleared>(_onActiveValueCleared);
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

  static const Set<String> _lengthOnlyKeys = {
    'Width',
    'Length',
    'Height',
    'Run',
    'Rise',
    'Diag',
    'Diameter',
    'Radius',
    'Chord',
    'Qty@OC',
  };

  static const String _dmsKey = 'DMS';

  void _onKeySelected(
    CalculatorKeySelected event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) {
    final id = event.id;
    if (_unitKeys[id] case final unit?) return _pressUnit(tape, unit);
    if (TrigFunction.named(id) case final function?) {
      return tape.pressTrigKey(function);
    }
    if (id == _dmsKey) return tape.pressDmsKey();
    return tape.pressFunctionKey(
      id,
      keyWantsUnit: !PlainNumberKeys.all.contains(id),
      readsDegrees: id == PlainNumberKeys.pitch,
    );
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
  ) => _press(emit, (tape) => _pressUnit(tape, event.unit));

  TapeOutcome _pressUnit(Tape tape, Unit unit) {
    final key = tape.beingTyped?.key;
    return tape.pressUnit(
      unit,
      holdsLengthOnly: _lengthOnlyKeys.contains(key),
      takesAGrade: key == PlainNumberKeys.slope,
    );
  }

  void _onActiveValueCleared(
    CalculatorActiveValueCleared event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.clearActive());

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
      // TODO: [CA-1195] Delete this arm when coreui removes moreOptions.
      // ignore: deprecated_member_use
      case ControlAction.moreOptions:
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
