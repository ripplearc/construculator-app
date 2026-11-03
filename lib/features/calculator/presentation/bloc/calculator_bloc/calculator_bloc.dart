import 'dart:async';

import 'package:construculator/features/calculator/domain/repositories/calculator_preferences_repository.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

part 'calculator_event.dart';
part 'calculator_setting.dart';
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
/// store or the recents. The engine's answers (the strip, the pills, the
/// equals-key label) are mapped in S1b (CA-1088).
///
/// The settings (W1, CA-1103) are the signed-in user's, watched from the
/// [CalculatorPreferencesRepository]: the tape renders under whatever
/// arrives (rule 4.14, "a setting re-renders a value; it never changes
/// what was typed"), the System of units pill and a setting sheet's Update
/// re-render at once and then save, so the tape, the keyboard and the
/// sheet agree on one value, and a save that fails says so without taking
/// the choice back. The toast after Update is raised from the save
/// ([CalculatorState.settingSaved]), not from a toast queue (S2b); Update
/// on the choice already in force closes the sheet with no save and no
/// toast, and the pill's save raises none. A sheet opening or closing is
/// not a key either: the Alert of the last key stays under the sheet and
/// is still there when it closes, as settings that arrive leave what the
/// last key said alone (decided 1 November 2026).
///
/// A save sends the change, never the whole row: the repository applies it
/// to the settings it holds once the signed-in profile has been read, so a
/// choice made before that profile arrives changes its own setting only
/// and the other four keep what the user saved. What the screen shows is
/// what last arrived with the saves still in flight applied on top — the
/// profile that lands after such a choice is shown with the choice still
/// on it, the echo of an older save cannot take a newer choice back, and a
/// change from another device during a save is shown with the in-flight
/// change on top until the save's own echo arrives, which is what the
/// profile then holds: the newest write wins, in the order the server took
/// them (decided 1 November 2026). A save stays in flight until its echo
/// arrives, and the echo of a newer save ends the older ones with it (the
/// repository lets only the newest echo due through); a save equal to the
/// stream's last emission — what last arrived, or the last echo still due
/// — is never echoed, since the distinct stream never repeats itself, so
/// that save leaves the list as it returns.
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final CalculatorPreferencesRepository _preferencesRepository;

  late final StreamSubscription<CalculatorPreferences> _preferencesSubscription;

  final List<_SaveInFlight> _savesInFlight = [];

  CalculatorPreferences _lastArrived = CalculatorPreferences.defaults;

  CalculatorPreferences get _lastEmitted {
    for (final save in _savesInFlight.reversed) {
      if (save.saved case final saved?) return saved;
    }
    return _lastArrived;
  }

  CalculatorBloc({
    required CalculatorPreferencesRepository preferencesRepository,
  }) : _preferencesRepository = preferencesRepository,
       super(CalculatorState.initial()) {
    on<CalculatorPreferencesArrived>(_onPreferencesArrived);
    on<CalculatorUnitSystemToggled>(_onUnitSystemToggled);
    on<CalculatorSettingSheetOpened>(_onSettingSheetOpened);
    on<CalculatorSettingSheetClosed>(_onSettingSheetClosed);
    on<CalculatorSettingUpdated>(_onSettingUpdated);
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
    _preferencesSubscription = preferencesRepository.watchPreferences().listen(
      (preferences) => add(CalculatorPreferencesArrived(preferences)),
    );
  }

  @override
  Future<void> close() async {
    await _preferencesSubscription.cancel();
    return super.close();
  }

  void _onPreferencesArrived(
    CalculatorPreferencesArrived event,
    Emitter<CalculatorState> emit,
  ) {
    _lastArrived = event.preferences;
    final echoed = _savesInFlight.indexWhere(
      (save) => save.saved == event.preferences,
    );
    if (echoed >= 0) _savesInFlight.removeRange(0, echoed + 1);
    final shown = _savesInFlight.fold(
      event.preferences,
      (preferences, save) => save.change(preferences),
    );
    emit(state.copyWith(tape: state.tape.withPreferences(shown)));
  }

  Future<void> _onUnitSystemToggled(
    CalculatorUnitSystemToggled event,
    Emitter<CalculatorState> emit,
  ) => _applySystem(emit, switch (state.tape.preferences.system) {
    MeasurementSystem.imperial => MeasurementSystem.metric,
    MeasurementSystem.metric => MeasurementSystem.imperial,
  });

  void _onSettingSheetOpened(
    CalculatorSettingSheetOpened event,
    Emitter<CalculatorState> emit,
  ) => emit(state.copyWith(openSettingSheet: () => event.setting));

  void _onSettingSheetClosed(
    CalculatorSettingSheetClosed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.openSettingSheet == null) return;
    emit(state.copyWith(openSettingSheet: () => null));
  }

  Future<void> _onSettingUpdated(
    CalculatorSettingUpdated event,
    Emitter<CalculatorState> emit,
  ) async {
    if (event.setting.selectedOptionId(state.tape.preferences) ==
        event.optionId) {
      return emit(state.copyWith(openSettingSheet: () => null));
    }
    CalculatorPreferences change(CalculatorPreferences current) =>
        event.setting.applied(current, event.optionId);
    emit(
      state.silenced.copyWith(
        tape: state.tape.withPreferences(change(state.tape.preferences)),
        openSettingSheet: () => null,
      ),
    );
    await _saved(emit, change, setting: event.setting);
  }

  Future<void> _saved(
    Emitter<CalculatorState> emit,
    CalculatorPreferences Function(CalculatorPreferences) change, {
    CalculatorSetting? setting,
  }) async {
    final save = _SaveInFlight(change);
    _savesInFlight.add(save);
    final result = await _preferencesRepository.updatePreferences(change);
    emit(
      result.fold(
        (failure) {
          _savesInFlight.remove(save);
          return state.copyWith(settingSaveFailure: () => failure);
        },
        (saved) {
          if (saved == _lastEmitted) {
            _savesInFlight.remove(save);
          } else {
            save.saved = saved;
          }
          return setting == null
              ? state
              : state.copyWith(settingSaved: () => setting);
        },
      ),
    );
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

  static const Map<String, TrigFunction> _trigKeys = {
    'SIN': TrigFunction.sine,
    'COS': TrigFunction.cosine,
    'TAN': TrigFunction.tangent,
    'ASIN': TrigFunction.arcsine,
    'ACOS': TrigFunction.arccosine,
    'ATAN': TrigFunction.arctangent,
  };

  static const String _dmsKey = 'DMS';

  void _onKeySelected(
    CalculatorKeySelected event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) {
    final id = event.id;
    if (_unitKeys[id] case final unit?) return _pressUnit(tape, unit);
    if (_trigKeys[id] case final function?) return tape.pressTrigKey(function);
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
      holdsLengthOnly: LengthOnlyKeys.all.contains(key),
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
  ) => emit(state.silenced.copyWith(currentGroupIndex: event.groupIndex));

  Future<void> _onUnitSystemChanged(
    CalculatorUnitSystemChanged event,
    Emitter<CalculatorState> emit,
  ) => _applySystem(emit, switch (event.unitSystem) {
    UnitSystem.imperial => MeasurementSystem.imperial,
    UnitSystem.metric => MeasurementSystem.metric,
  });

  Future<void> _applySystem(
    Emitter<CalculatorState> emit,
    MeasurementSystem system,
  ) async {
    CalculatorPreferences change(CalculatorPreferences current) =>
        current.copyWith(system: system);
    emit(
      state.silenced.copyWith(
        tape: state.tape.withPreferences(change(state.tape.preferences)),
      ),
    );
    await _saved(emit, change);
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
        emit(state.silenced.copyWith(tape: tape, notice: () => notice));
      case final TapeOutcome refusal:
        emit(state.silenced.copyWith(refusal: () => refusal));
    }
  }

  CalculatorState _cleared() => CalculatorState(
    tape: Tape(preferences: state.tape.preferences),
    currentGroupIndex: state.currentGroupIndex,
  );
}

class _SaveInFlight {
  final CalculatorPreferences Function(CalculatorPreferences) change;

  CalculatorPreferences? saved;

  _SaveInFlight(this.change);
}
