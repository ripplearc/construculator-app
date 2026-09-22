import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:construculator/libraries/calculator_engine/models/unit.dart';

/// Chooses the other spellings a value is offered in, per dimension (UX
/// Design Doc Section 6, "Conversions offered"; Appendix A).
///
/// A conversion never changes a value, only its unit, so every offer is the
/// same quantity re-spelled through `spelledIn`. Which spellings are offered
/// depends on the one the value already wears: from feet the trade wants
/// inches, yards and metres; from inches the ft-in compound and millimetres.
/// An angle's other spelling (degrees ⇄ D:M:S, the prototype's
/// `angleConversions` chip) arrives with the angle ticket; until then an
/// [Angle] offers nothing.
class UnitConverter {
  /// The smallest area, in acres, for which an acre reading is offered: a
  /// wall of 180ft² would read 0.0041acre, which is noise, not information.
  static const double smallestAcreOffer = 0.005;

  const UnitConverter();

  /// The value re-spelled in each unit the strip should offer, in the order
  /// the strip lists them. Empty when nothing is offered.
  List<Quantity> offersFor(Quantity value) => switch (value) {
    Length() =>
      (_lengthTargets[value.unit] ?? const [])
          .map(value.spelledIn)
          .toList(growable: false),
    Area() => [
      for (final unit in const [Unit.foot, Unit.yard, Unit.inch, Unit.metre])
        if (unit != value.unit) value.spelledIn(unit),
      if (value.squareFeet / Area.squareFeetPerAcre >= smallestAcreOffer &&
          value.unit != Unit.acre)
        value.spelledIn(Unit.acre),
    ],
    Volume() => [
      for (final unit in const [
        Unit.foot,
        Unit.yard,
        Unit.metre,
        Unit.boardFoot,
      ])
        if (unit != value.unit) value.spelledIn(unit),
    ],
    Weight() =>
      (_weightTargets[value.unit] ?? const [])
          .map(value.spelledIn)
          .toList(growable: false),
    Angle() || Scalar() => const [],
  };

  // The typed unit is left out and at most three readings are offered; from
  // inches the compound leads because 264in is easier to picture as 22ft 0in.
  // Centimetres and millimetres offer nothing, as in Appendix A.
  static const Map<Unit, List<Unit>> _lengthTargets = {
    Unit.foot: [Unit.inch, Unit.yard, Unit.metre],
    Unit.footInch: [Unit.inch, Unit.metre],
    Unit.inch: [Unit.footInch, Unit.millimetre],
    Unit.yard: [Unit.footInch, Unit.metre],
    Unit.metre: [Unit.footInch, Unit.inch],
  };

  static const Map<Unit, List<Unit>> _weightTargets = {
    Unit.pound: [Unit.kilogram, Unit.ton],
    Unit.kilogram: [Unit.pound, Unit.metricTon],
    Unit.ton: [Unit.pound, Unit.kilogram, Unit.metricTon],
    Unit.metricTon: [Unit.ton, Unit.kilogram, Unit.pound],
  };
}
