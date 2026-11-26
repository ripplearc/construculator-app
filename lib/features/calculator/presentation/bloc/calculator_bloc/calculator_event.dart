// coverage:ignore-file
part of 'calculator_bloc.dart';

/// What the keyboard and the display area ask of the tape (UX Design Doc
/// Section 1.3). Every event names a key; the bloc presses it on the tape
/// and the tape decides what it means.
sealed class CalculatorEvent extends Equatable {
  const CalculatorEvent();

  @override
  List<Object?> get props => [];
}

/// A function key was tapped, on the strip or in the "View all" sheet.
class CalculatorKeySelected extends CalculatorEvent {
  /// The stable, locale-independent id of the key — never its displayed
  /// label, which changes with locale.
  final String id;

  const CalculatorKeySelected(this.id);

  @override
  List<Object?> get props => [id];
}

/// A digit or the decimal point was pressed.
class CalculatorDigitPressed extends CalculatorEvent {
  /// The digit, or `.`.
  final String digit;

  const CalculatorDigitPressed(this.digit);

  @override
  List<Object?> get props => [digit];
}

/// The fraction key `/` was pressed: 1 [Feet] 1 [/] 16 [Inch] is 1ft 1/16in.
class CalculatorFractionPressed extends CalculatorEvent {
  const CalculatorFractionPressed();
}

/// A unit key of the keyboard's unit column was pressed.
class CalculatorUnitSelected extends CalculatorEvent {
  /// The unit the key stands for.
  final Unit unit;

  const CalculatorUnitSelected(this.unit);

  @override
  List<Object?> get props => [unit];
}

/// An arithmetic operator key was pressed.
class CalculatorOperatorPressed extends CalculatorEvent {
  /// The operator the key stands for.
  final Operator operator;

  const CalculatorOperatorPressed(this.operator);

  @override
  List<Object?> get props => [operator];
}

/// The % key was pressed (UX Design Doc Section 7, "Percent").
class CalculatorPercentPressed extends CalculatorEvent {
  const CalculatorPercentPressed();
}

/// The equals key was pressed.
class CalculatorEqualsPressed extends CalculatorEvent {
  const CalculatorEqualsPressed();
}

/// A control key was pressed: ⌫, C or the bracket key.
class CalculatorControlActioned extends CalculatorEvent {
  /// The control that was pressed.
  final ControlAction action;

  const CalculatorControlActioned(this.action);

  @override
  List<Object?> get props => [action];
}

/// A chip of the suggestion strip was tapped (Section 1.2): its answer
/// lands on the tape, or its conversion re-spells the value in place.
class CalculatorSuggestionAccepted extends CalculatorEvent {
  /// The chip that was tapped, as the state offered it.
  final CalculatorSuggestion suggestion;

  const CalculatorSuggestionAccepted(this.suggestion);

  @override
  List<Object?> get props => [suggestion];
}

/// The Read-as pill was tapped (term 2.14): the number is re-read the
/// other way, and a trig answer after it is rebuilt.
class CalculatorReadAsAccepted extends CalculatorEvent {
  const CalculatorReadAsAccepted();
}

/// A chip of the tape was tapped (Section 1.1: "Tap an input chip to edit
/// it"; rule 4.8): a finished value reopens in place, the chip being edited
/// seals, and a result says it is read, not edited.
class CalculatorChipTapped extends CalculatorEvent {
  /// Index of the chip on the tape, as the display lists it.
  final int index;

  const CalculatorChipTapped(this.index);

  @override
  List<Object?> get props => [index];
}

/// The display's ✕ was tapped: it clears the value being typed.
class CalculatorActiveValueCleared extends CalculatorEvent {
  const CalculatorActiveValueCleared();
}

/// A different group of function keys was selected.
class CalculatorGroupSelected extends CalculatorEvent {
  /// Index of the newly selected group.
  final int groupIndex;

  const CalculatorGroupSelected(this.groupIndex);

  @override
  List<Object?> get props => [groupIndex];
}

/// A group was dragged to a new place in the "View all" sheet (Section 1.5:
/// "The ⠿ handle drags a group into a new order").
/// The order of the function-key groups this phone keeps arrived from the
/// store, at the start and after every change (L3).
class CalculatorGroupOrderArrived extends CalculatorEvent {
  /// The five group ids in the order to show.
  final List<String> order;

  const CalculatorGroupOrderArrived(this.order);

  @override
  List<Object?> get props => [order];
}

class CalculatorGroupsReordered extends CalculatorEvent {
  /// Where the group was in the order the keyboard showed.
  final int oldIndex;

  /// Where the drag left it; the groups between shift by one.
  final int newIndex;

  const CalculatorGroupsReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// The System of units toggle was switched.
class CalculatorUnitSystemChanged extends CalculatorEvent {
  /// The newly selected system.
  final UnitSystem unitSystem;

  const CalculatorUnitSystemChanged(this.unitSystem);

  @override
  List<Object?> get props => [unitSystem];
}

/// The calculator should start again with an empty tape.
class CalculatorResetRequested extends CalculatorEvent {
  const CalculatorResetRequested();
}

/// The ✕ of the red Alert was tapped (Section 5: the message closes on its
/// ✕ or the next keypad key).
class CalculatorToastClosed extends CalculatorEvent {
  const CalculatorToastClosed();
}

/// The trade store answered, or changed, for the area the bloc is watching
/// (requirement R9): the counts of that area at every stored size, in the
/// user's order; none once the area they were counted for has left the
/// display. Not a key: what the last key said stays.
class CalculatorMaterialCountsArrived extends CalculatorEvent {
  /// The counts, one per stored size.
  final List<TradeCount> counts;

  const CalculatorMaterialCountsArrived(this.counts);

  @override
  List<Object?> get props => [counts];
}

/// A row of the detail panel's sheet table was deleted, by its trash
/// button or a swipe (Section 1.4). The row and its chip leave at once and
/// the size is removed from the store; a delete the store refuses puts
/// them back, unless the store has answered since. Not a key: the tape and
/// what the last key said stay.
class CalculatorSizeRowDeleted extends CalculatorEvent {
  /// The [CalculatorSizeRow.id] of the row.
  final String rowId;

  const CalculatorSizeRowDeleted(this.rowId);

  @override
  List<Object?> get props => [rowId];
}

/// The size editor opened from "+ Add size" in the detail panel's sheet
/// table closed (Section 1.4; term 2.18). Closed with Add, [fields] holds
/// the Length and Width fields as typed, and the size, width first, is
/// added to the drywall store; its count reaches the table and the strip
/// through the open watch (R9). Closed any other way, [fields] is empty and
/// nothing is added, as it is for a field that spells no size, which the
/// editor refuses before Add. Not a key: the tape and what the last key
/// said stay.
class CalculatorSizeEditorClosed extends CalculatorEvent {
  /// The editor's fields: Length (the new size's width), then Width (its
  /// height); empty when the editor closed without Add.
  final List<String> fields;

  const CalculatorSizeEditorClosed(this.fields);

  @override
  List<Object?> get props => [fields];
}
