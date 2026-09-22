import 'package:construculator/libraries/calculator_engine/models/dimension.dart';

/// A unit a calculator value can be typed in or shown in.
///
/// The unit keys of the keyboard (Yards, Feet, Inch, m, cm, mm, Lbs, Kg,
/// Tons, m Tons, Bd Ft) each map to one member, and a few members exist only
/// as spellings a value can be converted into: [footInch] is the trade
/// compound (18ft 8in) and [acre] is offered for large areas. Squared and
/// cubed forms are not separate units: an area or a volume carries the
/// length unit it is written in, and the dimension supplies the exponent.
enum Unit {
  /// Inches; 64 ticks.
  inch('in', Dimension.length),

  /// Feet; 768 ticks.
  foot('ft', Dimension.length),

  /// The trade compound of feet and whole inches (18ft 8in). Never typed as
  /// one key: it is what two tokens spell, or what [foot] converts to when the
  /// value has leftover inches.
  footInch('ft in', Dimension.length),

  /// Yards; 2,304 ticks.
  yard('yd', Dimension.length),

  /// Metres, converted on entry at 2,519.685 ticks per metre.
  metre('m', Dimension.length),

  /// Centimetres.
  centimetre('cm', Dimension.length),

  /// Millimetres.
  millimetre('mm', Dimension.length),

  /// Acres; offered as a conversion once an area is at least 0.005 acre.
  acre('acre', Dimension.area),

  /// Pounds, the canonical weight unit.
  pound('lbs', Dimension.weight),

  /// Kilograms.
  kilogram('kg', Dimension.weight),

  /// Tons; how many pounds make one is the "Pounds per ton" setting, so this
  /// member carries no factor of its own (see [hundredthsOfPoundPer]).
  ton('ton', Dimension.weight),

  /// Metric tons of 1,000 kg.
  metricTon(' m tons', Dimension.weight),

  /// Board feet: 1/12 of a cubic foot, a spelling of volume.
  boardFoot('bf', Dimension.volume);

  /// The text written straight after the number, as the tape spells it
  /// ("22ft", "78lbs", "12 m tons").
  final String suffix;

  /// The dimension a bare number takes when this unit closes it.
  final Dimension dimension;

  const Unit(this.suffix, this.dimension);

  /// Ticks of 1/64 inch in one of this unit.
  ///
  /// Only length units have a tick count; asking a weight or volume unit for
  /// one is a programming error, not a value the caller can recover from.
  double get ticksPerUnit => switch (this) {
    inch => 64,
    foot || footInch => 768,
    yard => 2304,
    metre => 2519.685,
    centimetre => 25.196850394,
    millimetre => 2.5196850394,
    acre ||
    pound ||
    kilogram ||
    ton ||
    metricTon ||
    boardFoot => throw StateError('$name is not a length unit'),
  };

  /// Hundredths of a pound in one of this unit, given how many pounds the
  /// "Pounds per ton" setting puts in a ton (2,000 by default, 2,240 for the
  /// long ton).
  ///
  /// The setting is a parameter rather than a stored preference because it
  /// changes how a stored weight is read on the way in and on the way out,
  /// never the weight itself (UX Design Doc rule 4.14).
  double hundredthsOfPoundPer({required int poundsPerTon}) => switch (this) {
    pound => 100,
    kilogram => 220.462262,
    ton => poundsPerTon * 100.0,
    metricTon => 220462.262,
    inch ||
    foot ||
    footInch ||
    yard ||
    metre ||
    centimetre ||
    millimetre ||
    acre ||
    boardFoot => throw StateError('$name is not a weight unit'),
  };

  /// Whether this unit belongs to the metric system.
  ///
  /// A compound value steps down within one system only (18ft 8in, 1m 20cm),
  /// so the system decides whether a second unit may continue a number.
  bool get isMetric => switch (this) {
    metre || centimetre || millimetre || kilogram || metricTon => true,
    inch ||
    foot ||
    footInch ||
    yard ||
    acre ||
    pound ||
    ton ||
    boardFoot => false,
  };

  /// Where this length unit sits in its system's compound order: a compound
  /// may only step down, from a higher rank to a lower one (yd → ft → in,
  /// m → cm → mm). Zero for every unit that cannot take part in a compound.
  int get compoundRank => switch (this) {
    yard || metre => 3,
    foot || footInch || centimetre => 2,
    inch || millimetre => 1,
    acre || pound || kilogram || ton || metricTon || boardFoot => 0,
  };

  /// The length units, in the order the imperial and metric key columns
  /// list them.
  static const List<Unit> lengthUnits = [
    yard,
    foot,
    inch,
    metre,
    centimetre,
    millimetre,
  ];

  /// The weight units, in the order of the Unit group.
  static const List<Unit> weightUnits = [pound, kilogram, ton, metricTon];
}
