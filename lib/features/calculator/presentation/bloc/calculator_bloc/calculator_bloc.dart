import 'dart:async';

import 'package:construculator/features/calculator/domain/usecases/add_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/bank_calculation_session_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_calculation_session_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/delete_material_size_usecase.dart';
import 'package:construculator/features/calculator/domain/usecases/watch_trade_stores_usecase.dart';
import 'package:construculator/features/calculator/presentation/formatters/size_entry_parser.dart';
import 'package:construculator/libraries/calculator_engine/calculator_engine.dart';
import 'package:construculator/libraries/errors/calculator_error_type.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

part 'calculator_dependent_key.dart';
part 'calculator_display_label.dart';
part 'calculator_event.dart';
part 'calculator_group_id.dart';
part 'dependent_key_id.dart';
part 'calculator_size_table.dart';
part 'calculator_state.dart';
part 'calculator_strip_note.dart';
part 'calculator_suggestion.dart';
part 'calculator_toast.dart';

/// Presses the keyboard's keys on the engine's tape and keeps the tape as
/// its state (UX Design Doc Sections 1.1, 1.3 and 4; CA-1087, S1a).
///
/// The bloc holds no arithmetic and no rule of its own: each event is one
/// call on [Tape], whose outcome is folded into the state — a changed tape
/// with its notice, or the same tape with the refusal. What it does know
/// is which key is which: the Unit group's keys press their unit, a trig
/// key and the D:M:S key press theirs, Pitch, Slope and Sides take a plain
/// number ([PlainNumberKeys]), and a unit under a length-only key (Section
/// 3, "Takes: A length"), under Pitch (which takes a bare number, a length
/// or a D:M:S entry and never an area or a weight: Section 5, "keeps", "at
/// any time under Pitch") or under Slope goes to the tape with that said,
/// read off the chip being typed wherever it is. Nothing here reads the
/// recents or the preferences repository; the System of units toggle sets
/// the tape's own preferences, so the tape and the keyboard agree on one
/// value.
///
/// The stores it reads are the trade stores, through
/// [WatchTradeStoresUseCase] (S2a, CA-1090; G1, CA-1072; requirement R9):
/// while the state's [CalculatorState.areaForCounts] names an area the bloc
/// watches the stores under the unit system in force, and every answer —
/// the first, and each change to a store after it — arrives as
/// [CalculatorTradeStoresArrived] and is kept in the state for the ladder.
/// The watch ends when the area leaves the display, and with the bloc.
/// Which area is counted and what the strip offers for it is the engine's
/// [Arbiter], which the state asks.
///
/// The strip is the ladder's reading of the same tape (CA-1088, S1b; G1):
/// accepting a chip lands the answer the engine had already computed, so
/// nothing is recalculated on tap (Section 1.2). An answer lands through
/// [Tape.landAnswer], as does a sheet count of the area on the display
/// ([CalculatorState.materialCounts]; S2a, CA-1090), under
/// the trade's result key, Number of sheets; the running total through =, a conversion through
/// [Tape.acceptConversion], the unit key of its spelling (rule 4.3) with a
/// ft-in chip read as the strip wrote it (3ft 3-3/8in; decision tree row
/// 201), and an angle's other spelling through the D:M:S key (Section
/// 3.5). A chip the strip no longer offers — tapped again before the strip
/// redrew — changes nothing. = lands the leading suggestion when the strip
/// has one (term 2.15: "= still lands that suggestion"), else the tape's
/// own equals.
///
/// A finished tape is banked to history without being asked (U1, CA-1097;
/// rule 4.9, term 2.19): when a key opens a fresh chip straight after an
/// answer or an error — a digit, a function key, a trig key that cannot use
/// the answer, the bracket key, or an operator, which carries the answer
/// forward as the Calc chip of the new tape — when C clears a tape that
/// holds a result, and when the calculator is left with more on the tape
/// than a value still being typed. A dimension key after an answer banks
/// too, whatever the tape holds (decision tree row 32: "Rise 6 in Run 12 in
/// = then Width: Pitch tape goes to history"). A Materials key goes on with
/// the tape and banks nothing: it asks for a calculation on what the tape
/// holds (term 2.7; rows 457 and 460). The key does its job at
/// once; the "Saved to history" card shows when the store has taken the
/// tape ([CalculatorSessionBanked]), and Undo takes the session out of
/// history again behind the tape it brings back (walkthrough 13.2). Leaving
/// banks once, however often the bloc is closed.
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  final WatchTradeStoresUseCase _tradeStores;
  final DeleteMaterialSizeUseCase _deleteMaterialSize;
  final AddMaterialSizeUseCase _addMaterialSize;
  final BankCalculationSessionUseCase _bankSession;
  final DeleteCalculationSessionUseCase _deleteSession;

  static final _logger = AppLogger().tag('CalculatorBloc');

  StreamSubscription<TradeStores>? _storesSubscription;

  MeasurementSystem? _watchedSystem;

  /// Creates the bloc over the use cases that read the trade stores, add a
  /// size to a store or remove one, and bank a tape to history or take it
  /// out again.
  CalculatorBloc({
    required this._tradeStores,
    required this._deleteMaterialSize,
    required this._addMaterialSize,
    required this._bankSession,
    required this._deleteSession,
  }) : super(CalculatorState.initial()) {
    on<CalculatorTradeStoresArrived>(_onTradeStoresArrived);
    on<CalculatorSizeRowDeleted>(_onSizeRowDeleted);
    on<CalculatorSizeEditorClosed>(_onSizeEditorClosed);
    on<CalculatorKeySelected>(_onKeySelected);
    on<CalculatorDigitPressed>(_onDigitPressed);
    on<CalculatorFractionPressed>(_onFractionPressed);
    on<CalculatorUnitSelected>(_onUnitSelected);
    on<CalculatorOperatorPressed>(_onOperatorPressed);
    on<CalculatorPercentPressed>(_onPercentPressed);
    on<CalculatorEqualsPressed>(_onEqualsPressed);
    on<CalculatorSuggestionAccepted>(_onSuggestionAccepted);
    on<CalculatorReadAsAccepted>(_onReadAsAccepted);
    on<CalculatorControlActioned>(_onControlActioned);
    on<CalculatorActiveValueCleared>(_onActiveValueCleared);
    on<CalculatorChipTapped>(_onChipTapped);
    on<CalculatorGroupSelected>(_onGroupSelected);
    on<CalculatorGroupsReordered>(_onGroupsReordered);
    on<CalculatorHistoryStageChanged>(_onHistoryStageChanged);
    on<CalculatorKeypadFoldChanged>(_onKeypadFoldChanged);
    on<CalculatorSessionBanked>(_onSessionBanked);
    on<CalculatorUndoPressed>(_onUndoPressed);
    on<CalculatorHistoryViewPressed>(_onHistoryViewPressed);
    on<CalculatorUnitSystemChanged>(_onUnitSystemChanged);
    on<CalculatorResetRequested>(_onResetRequested);
    on<CalculatorToastClosed>(_onToastClosed);
  }

  @override
  void onChange(Change<CalculatorState> change) {
    super.onChange(change);
    _followTheAreaOnScreen(change.nextState);
  }

  @override
  Future<void> close() async {
    if (!isClosed && state.holdsWorkToBank) await _bankSession(state.tape);
    await _storesSubscription?.cancel();
    return super.close();
  }

  void _followTheAreaOnScreen(CalculatorState next) {
    final system = next.areaForCounts == null
        ? null
        : next.tape.preferences.system;
    if (system == _watchedSystem) return;
    unawaited(_storesSubscription?.cancel());
    _storesSubscription = null;
    _watchedSystem = system;
    if (system == null) {
      if (next.stores != const TradeStores()) {
        add(const CalculatorTradeStoresArrived(TradeStores()));
      }
      return;
    }
    _storesSubscription = _tradeStores(system: system).listen(
      (stores) => add(CalculatorTradeStoresArrived(stores)),
      // The strip keeps what it showed. Warning level: the error-level
      // log belongs to the store's own boundary, not to a bloc.
      onError: (Object error, StackTrace stackTrace) =>
          _logger.warning('The trade stores watch failed', error, stackTrace),
    );
  }

  void _onTradeStoresArrived(
    CalculatorTradeStoresArrived event,
    Emitter<CalculatorState> emit,
  ) {
    // stores that answered for an area no longer on the display
    if (_watchedSystem == null && event.stores != const TradeStores()) return;
    emit(state.copyWith(stores: event.stores));
  }

  Future<void> _onSizeRowDeleted(
    CalculatorSizeRowDeleted event,
    Emitter<CalculatorState> emit,
  ) async {
    final row = state.sizeTable?.rows
        .where((row) => row.id == event.rowId)
        .firstOrNull;
    if (row == null) return;
    final stores = state.stores;
    final remaining = TradeStores(
      sheetSizes: [
        for (final size in stores.sheetSizes)
          if (!identical(size, row.count.size)) size,
      ],
      masonrySizes: stores.masonrySizes,
    );
    // A swiped row must be gone by the next frame, so it leaves before the
    // store answers.
    emit(state.copyWith(stores: remaining));
    final deleted = await _deleteMaterialSize(
      trade: row.count.trade,
      size: row.count.size,
      system: state.tape.preferences.system,
    );
    if (deleted.isLeft() && identical(state.stores, remaining)) {
      emit(state.copyWith(stores: stores));
    }
  }

  Future<void> _onSizeEditorClosed(
    CalculatorSizeEditorClosed event,
    Emitter<CalculatorState> emit,
  ) async {
    if (event.fields case [final lengthText, final widthText]) {
      final width = state.sizeEntryLength(lengthText);
      final height = state.sizeEntryLength(widthText);
      if (width == null || height == null) return;
      final added = await _addMaterialSize(
        trade: Trade.drywall,
        width: width,
        height: height,
      );
      added.fold((failure) {
        // Nobody signed in is the app's to answer, with the sign-in
        // screen; any other refusal the user is told about here.
        // TODO: [CA-1538] Keep the editor open with both values instead,
        // once CoreUI lets the app answer Add before the sheet closes.
        // https://ripplearc.youtrack.cloud/issue/CA-1538
        if (failure case CalculatorFailure(
          errorType: CalculatorErrorType.notSignedIn,
        )) {
          return;
        }
        _emitCountingToast(
          emit,
          state.copyWith(sizeNotAdded: true, toastClosed: false),
        );
      }, (_) {});
    }
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

  static const Set<String> _materialsKeys = {
    'Msnry',
    'Drywal',
    'Footng',
    'Fence',
    'Qty@OC',
    'Cost',
    'Weight',
  };

  void _onKeySelected(
    CalculatorKeySelected event,
    Emitter<CalculatorState> emit,
  ) {
    final id = event.id;
    if (_unitKeys[id] case final unit?) {
      return _press(emit, (tape) => _pressUnit(tape, unit), unit: unit);
    }
    _press(emit, (tape) {
      if (_trigKeys[id] case final function?) {
        return tape.pressTrigKey(function);
      }
      if (id == _dmsKey) return tape.pressDmsKey();
      return tape.pressFunctionKey(
        id,
        keyWantsUnit: !PlainNumberKeys.all.contains(id),
        readsDegrees: id == PlainNumberKeys.pitch,
      );
    }, goesOnWithTheTape: _materialsKeys.contains(id));
  }

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
  ) => _press(emit, (tape) => _pressUnit(tape, event.unit), unit: event.unit);

  TapeOutcome _pressUnit(Tape tape, Unit unit) => tape.pressUnit(
    unit,
    holdsLengthOnly: _holdsLengthOnly(tape),
    takesAGrade: _takesAGrade(tape),
    takesACount: _takesACount(tape),
  );

  bool _holdsLengthOnly(Tape tape) {
    final key = tape.beingTyped?.key;
    return LengthOnlyKeys.all.contains(key) || key == PlainNumberKeys.pitch;
  }

  bool _takesAGrade(Tape tape) => tape.beingTyped?.key == PlainNumberKeys.slope;

  bool _takesACount(Tape tape) => tape.beingTyped?.key == PlainNumberKeys.sides;

  void _onReadAsAccepted(
    CalculatorReadAsAccepted event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.reInput());

  void _onChipTapped(
    CalculatorChipTapped event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.tapChip(event.index));

  void _onActiveValueCleared(
    CalculatorActiveValueCleared event,
    Emitter<CalculatorState> emit,
  ) {
    final outcome = state.tape.clearActive();
    // With no value in progress the tape refuses ✕, and that is the key's
    // other meaning (Section 1.1): the state says "closes" in place of it.
    // Inside a bracket the bracket itself is in progress, so there the
    // tape's answer stands (Section 7: 2 + (3 + ✕ 4) = is 9).
    if (state.tape.openBracket == null &&
        outcome == const TapeRefused(TapeRefusal.nothingBeingTyped)) {
      emit(
        state.copyWith(
          notice: () => null,
          refusal: () => null,
          removedResults: const [],
          refusedUnit: () => null,
          closesCalculator: true,
        ),
      );
      return;
    }
    _fold(emit, outcome);
  }

  void _onOperatorPressed(
    CalculatorOperatorPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.pressOperator(event.operator));

  void _onPercentPressed(
    CalculatorPercentPressed event,
    Emitter<CalculatorState> emit,
  ) => _press(emit, (tape) => tape.pressPercent());

  void _onEqualsPressed(
    CalculatorEqualsPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.equalsLands case final leading?) {
      return _accept(emit, leading);
    }
    _press(emit, (tape) => tape.pressEquals());
  }

  void _onSuggestionAccepted(
    CalculatorSuggestionAccepted event,
    Emitter<CalculatorState> emit,
  ) => _accept(emit, event.suggestion);

  void _accept(Emitter<CalculatorState> emit, CalculatorSuggestion suggestion) {
    if (!state.suggestions.contains(suggestion) &&
        !state.conversions.contains(suggestion)) {
      return _press(emit, TapeChanged.new);
    }
    switch ((suggestion.kind, suggestion.key, suggestion.count)) {
      case (CalculatorSuggestionKind.answer, final key?, _):
        _press(emit, (tape) => tape.landAnswer(key, suggestion.value));
      case (CalculatorSuggestionKind.runningTotal, _, _):
        _press(emit, (tape) => tape.pressEquals());
      case (CalculatorSuggestionKind.conversion, _, _):
        _press(emit, (tape) => _converted(tape, suggestion.value));
      // the count lands under the trade's result key (Number of sheets), not
      // under the offer's name (Drywall), with the size it was made at
      case (CalculatorSuggestionKind.materialCount, _, final count?):
        _press(
          emit,
          (tape) => tape.landAnswer(
            count.trade.resultKey,
            count.value,
            size: count.size,
          ),
        );
      case (CalculatorSuggestionKind.answer, null, _) ||
          (CalculatorSuggestionKind.materialCount, _, null):
        _press(emit, TapeChanged.new);
    }
  }

  TapeOutcome _converted(Tape tape, Quantity spelling) => switch (spelling) {
    Angle() => tape.pressDmsKey(),
    Length() || Area() || Volume() || Weight() => tape.acceptConversion(
      spelling,
      holdsLengthOnly: _holdsLengthOnly(tape),
      takesAGrade: _takesAGrade(tape),
    ),
    Scalar() => TapeChanged(tape),
  };

  void _onControlActioned(
    CalculatorControlActioned event,
    Emitter<CalculatorState> emit,
  ) {
    switch (event.action) {
      case ControlAction.delete:
        _press(emit, (tape) => tape.backspace());
      case ControlAction.clearAll:
        final cleared = state.tape;
        emit(_cleared());
        if (cleared.chips.any((chip) => chip is ResultChip)) {
          unawaited(_bank(cleared));
        }
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

  void _onHistoryStageChanged(
    CalculatorHistoryStageChanged event,
    Emitter<CalculatorState> emit,
  ) => emit(state.copyWith(historyStage: event.stage));

  void _onKeypadFoldChanged(
    CalculatorKeypadFoldChanged event,
    Emitter<CalculatorState> emit,
  ) => emit(state.copyWith(isKeypadFolded: event.isFolded));

  void _onSessionBanked(
    CalculatorSessionBanked event,
    Emitter<CalculatorState> emit,
  ) => _emitCountingToast(
    emit,
    state.copyWith(
      bankedTape: () => event.tape,
      bankedSessionId: () => event.sessionId,
      bankedCarriedForward: event.carriedForward,
      toastClosed: false,
    ),
  );

  Future<void> _onUndoPressed(
    CalculatorUndoPressed event,
    Emitter<CalculatorState> emit,
  ) async {
    final banked = state.bankedTape;
    if (banked == null) return;
    final sessionId = state.bankedSessionId;
    emit(
      state.copyWith(
        tape: banked,
        bankedTape: () => null,
        bankedSessionId: () => null,
      ),
    );
    if (sessionId != null) await _deleteSession(sessionId);
  }

  void _onHistoryViewPressed(
    CalculatorHistoryViewPressed event,
    Emitter<CalculatorState> emit,
  ) => emit(
    state.copyWith(
      historyStage: DisplayAreaStage.fullScreen,
      bankedTape: () => null,
      bankedSessionId: () => null,
    ),
  );

  void _onGroupsReordered(
    CalculatorGroupsReordered event,
    Emitter<CalculatorState> emit,
  ) {
    final order = [...state.groupOrder];
    final CalculatorGroupsReordered(:oldIndex, :newIndex) = event;
    bool inRange(int index) => index >= 0 && index < order.length;
    if (!inRange(oldIndex) || !inRange(newIndex) || oldIndex == newIndex) {
      return;
    }
    final shown = order[state.currentGroupIndex];
    order.insert(newIndex, order.removeAt(oldIndex));
    emit(
      state.copyWith(
        groupOrder: List.unmodifiable(order),
        currentGroupIndex: order.indexOf(shown),
      ),
    );
  }

  void _onUnitSystemChanged(
    CalculatorUnitSystemChanged event,
    Emitter<CalculatorState> emit,
  ) {
    if (!state.tape.isEmpty) return;
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
    TapeOutcome Function(Tape tape) press, {
    Unit? unit,
    bool goesOnWithTheTape = false,
  }) => _fold(
    emit,
    press(state.tape),
    unit: unit,
    goesOnWithTheTape: goesOnWithTheTape,
  );

  void _fold(
    Emitter<CalculatorState> emit,
    TapeOutcome outcome, {
    Unit? unit,
    bool goesOnWithTheTape = false,
  }) {
    switch (outcome) {
      case TapeChanged(:final tape, :final notice, :final removed):
        final session = goesOnWithTheTape
            ? null
            : _newSessionOpenedBy(state.tape, tape);
        _emitCountingToast(
          emit,
          state.copyWith(
            tape: session?.fresh ?? tape,
            notice: () => notice,
            refusal: () => null,
            closesCalculator: false,
            removedResults: removed,
            refusedUnit: () => null,
            toastClosed: false,
            sizeNotAdded: false,
            bankedTape: () => null,
            bankedSessionId: () => null,
            groupEditsNoticed: notice == TapeNotice.editingThisGroup
                ? state.groupEditsNoticed + 1
                : null,
          ),
        );
        if (session != null) {
          unawaited(
            _bank(session.finished, carriedForward: session.carriedForward),
          );
        }
      case final TapeOutcome refusal:
        _emitCountingToast(
          emit,
          state.copyWith(
            notice: () => null,
            refusal: () => refusal,
            closesCalculator: false,
            removedResults: const [],
            refusedUnit: () => unit,
            toastClosed: false,
            sizeNotAdded: false,
            bankedTape: () => null,
            bankedSessionId: () => null,
          ),
        );
    }
  }

  // A fresh chip opened straight after an answer or an error starts a new
  // session (rules 4.9 and 4.12): what stood before the chip goes to
  // history and the chip opens a clean tape, behind the answer as a Calc
  // chip when an operator carried it forward. A dimension key after an
  // answer starts one only when the tape holds no named value to build on.
  // `null` for any other key.
  ({Tape finished, Tape fresh, bool carriedForward})? _newSessionOpenedBy(
    Tape before,
    Tape after,
  ) {
    if (after.chips.length != before.chips.length + 1) return null;
    final opened = after.chips.last;
    final finished = after.chips.sublist(0, before.chips.length);
    final opensAfresh = switch ((before.chips.lastOrNull, opened)) {
      (ResultChip() || ErrorChip(), ValueChip() || BracketChip(isOpen: true)) =>
        true,
      _ => false,
    };
    if (!opensAfresh) return null;
    final carried = switch ((finished.last, opened)) {
      (ResultChip(:final value), ValueChip(operator: _?)) => ResultChip(
        key: Tape.calcKey,
        value: value,
      ),
      _ => null,
    };
    return (
      finished: Tape(chips: finished, preferences: after.preferences),
      fresh: Tape(chips: [?carried, opened], preferences: after.preferences),
      carriedForward: carried != null,
    );
  }

  // The card says "Saved to history", so it shows only once the store has
  // taken the tape; a tape the store refused shows none.
  Future<void> _bank(Tape tape, {bool carriedForward = false}) async {
    final banked = await _bankSession(tape);
    if (isClosed) return;
    banked.fold(
      (_) {},
      (session) => add(
        CalculatorSessionBanked(
          tape,
          sessionId: session.id,
          carriedForward: carriedForward,
        ),
      ),
    );
  }

  void _emitCountingToast(
    Emitter<CalculatorState> emit,
    CalculatorState next,
  ) => emit(
    // the same guard raised twice over is a new state twice over, so the
    // page announces it again (rule 4.12)
    next.toast == null
        ? next
        : next.copyWith(toastsRaised: next.toastsRaised + 1),
  );

  void _onToastClosed(
    CalculatorToastClosed event,
    Emitter<CalculatorState> emit,
  ) => emit(state.copyWith(toastClosed: true));

  CalculatorState _cleared() => CalculatorState(
    tape: Tape(preferences: state.tape.preferences),
    currentGroupIndex: state.currentGroupIndex,
    groupOrder: state.groupOrder,
    historyStage: state.historyStage,
    isKeypadFolded: state.isKeypadFolded,
    toastsRaised: state.toastsRaised,
    groupEditsNoticed: state.groupEditsNoticed,
  );
}
