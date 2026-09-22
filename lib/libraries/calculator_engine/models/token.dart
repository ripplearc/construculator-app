import 'package:construculator/libraries/calculator_engine/models/unit.dart';
import 'package:equatable/equatable.dart';

/// One number of a value exactly as it was typed: its digits, the fraction
/// under them if [/] was pressed, the unit key that closed it, and how many
/// times that key was pressed.
///
/// A value is a list of tokens because the trade writes compounds: 18ft 8in
/// is two tokens, 1ft 1/16in is two tokens with a fraction on the second.
/// A token keeps its digits as text rather than a number so that the tape
/// can echo exactly what was typed ("0.", "7/", "1ft 1") while the number
/// is still open (UX Design Doc rule 4.1).
class Token extends Equatable {
  /// The digits typed so far, possibly with one decimal point; empty while
  /// nothing has been typed into this token yet.
  final String digits;

  /// The denominator typed after [/]: `null` when the number has no fraction,
  /// empty while [/] has been pressed but no denominator typed yet.
  final String? denominator;

  /// The unit key that closed the number, or `null` while it is still open.
  final Unit? unit;

  /// How many times the closing unit was pressed: 1 for a length, 2 for its
  /// square (ft²) and 3 for its cube (ft³). The ladder stops at cubic
  /// (rule 4.3).
  final int power;

  const Token({
    required this.digits,
    this.denominator,
    this.unit,
    this.power = 1,
  }) : assert(power >= 1 && power <= 3, 'the unit ladder stops at cubic');

  /// Whether this token can be read as a number: it has digits, a unit, and
  /// no fraction left half-typed. Only complete tokens have a value.
  bool get isComplete => digits.isNotEmpty && unit != null && denominator != '';

  /// The typed number: the digits divided by the denominator when there is
  /// one. Exact only in the sense the user typed it; a length becomes exact
  /// once it is turned into ticks.
  double get value {
    final numerator = double.tryParse(digits) ?? 0;
    final denominatorValue = double.tryParse(denominator ?? '');
    if (denominatorValue == null) return numerator;
    return numerator / denominatorValue;
  }

  /// Returns a copy with the given fields replaced. [denominator] and
  /// [unit] take a `Function()?` wrapper so that clearing them to `null` can
  /// be told apart from leaving them as they are.
  Token copyWith({
    String? digits,
    String? Function()? denominator,
    Unit? Function()? unit,
    int? power,
  }) {
    return Token(
      digits: digits ?? this.digits,
      denominator: denominator != null ? denominator() : this.denominator,
      unit: unit != null ? unit() : this.unit,
      power: power ?? this.power,
    );
  }

  @override
  List<Object?> get props => [digits, denominator, unit, power];
}
