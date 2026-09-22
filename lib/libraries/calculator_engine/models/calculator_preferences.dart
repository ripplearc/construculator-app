import 'package:equatable/equatable.dart';

/// The system of units the calculator's key column and rendered sizes
/// follow (UX Design Doc Appendix C, "System of units").
enum MeasurementSystem {
  /// Yards, feet and inches; stored sizes in inches; weights in tons.
  imperial,

  /// Metres, centimetres and millimetres; stored sizes in whole
  /// millimetres; weights in metric tons.
  metric,
}

/// The step a fraction of an inch is rounded to at display (Appendix C,
/// "Fractional resolution"). Rounding is part of the behaviour (rule 4.15):
/// 10in ÷ 3 reads 3-5/16in at 1/16 and 3-1/2in at 1/2.
enum FractionResolution {
  /// Nearest 1/2 inch.
  half(2),

  /// Nearest 1/4 inch.
  quarter(4),

  /// Nearest 1/8 inch.
  eighth(8),

  /// Nearest 1/16 inch, the default.
  sixteenth(16),

  /// Nearest 1/32 inch.
  thirtySecond(32),

  /// Nearest 1/64 inch, one tick: no rounding at all.
  sixtyFourth(64);

  /// The denominator of the step: 16 for 1/16.
  final int denominator;

  const FractionResolution(this.denominator);
}

/// How many decimals a length shown in metres keeps (Appendix C, "Meter
/// length display").
enum MetreDisplay {
  /// 0.0
  oneDecimal(1),

  /// 0.00, the default.
  twoDecimals(2),

  /// 0.000
  threeDecimals(3);

  /// The decimals kept.
  final int decimals;

  const MetreDisplay(this.decimals);
}

/// How many pounds make a ton (Appendix C, "Pounds per ton"). Changes how
/// every weight in tons is read, on entry and at display, never the weight.
enum TonDefinition {
  /// The US short ton of 2,000 lb, the default.
  shortTon(2000),

  /// The long ton of 2,240 lb.
  longTon(2240);

  /// Pounds in one ton.
  final int poundsPerTon;

  const TonDefinition(this.poundsPerTon);
}

/// The unit the densities table and the Density pill render in (Appendix
/// C, "Density display unit"). Densities are stored in lbs/yd³.
enum DensityUnit {
  /// lbs/yd³, the imperial default.
  poundsPerCubicYard,

  /// lbs/ft³.
  poundsPerCubicFoot,

  /// tons/yd³, tons as the "Pounds per ton" setting defines them.
  tonsPerCubicYard,

  /// kg/m³, the metric default.
  kilogramsPerCubicMetre;

  /// The unit a fresh install renders densities in under [system].
  static DensityUnit defaultFor(MeasurementSystem system) => switch (system) {
    MeasurementSystem.imperial => poundsPerCubicYard,
    MeasurementSystem.metric => kilogramsPerCubicMetre,
  };
}

/// The five calculator settings (UX Design Doc term 2.20, Appendix C).
///
/// A setting changes how a stored value is rendered, never the value itself
/// (rule 4.14), which is why this type has no place in the engine's
/// arithmetic and is only read by the formatter and, for the ton, the
/// parser. There is no setting for length display format, millimetre
/// decimals, strip layout or edit behaviour: those prototype preferences
/// were dropped by the UX doc and must not come back as keys.
class CalculatorPreferences extends Equatable {
  /// The system of units.
  final MeasurementSystem system;

  /// The step fractions of an inch round to.
  final FractionResolution fractionResolution;

  /// The decimals of a length shown in metres.
  final MetreDisplay metreDisplay;

  /// How many pounds make a ton.
  final TonDefinition tonDefinition;

  /// The unit densities render in.
  final DensityUnit densityUnit;

  const CalculatorPreferences({
    this.system = MeasurementSystem.imperial,
    this.fractionResolution = FractionResolution.sixteenth,
    this.metreDisplay = MetreDisplay.twoDecimals,
    this.tonDefinition = TonDefinition.shortTon,
    this.densityUnit = DensityUnit.poundsPerCubicYard,
  });

  /// The settings of a fresh install: Imperial, 1/16, 0.00, 2,000 lb,
  /// lbs/yd³.
  static const CalculatorPreferences defaults = CalculatorPreferences();

  /// Pounds in a ton, as the parser and the formatter read it.
  int get poundsPerTon => tonDefinition.poundsPerTon;

  /// Returns a copy with the given settings replaced.
  CalculatorPreferences copyWith({
    MeasurementSystem? system,
    FractionResolution? fractionResolution,
    MetreDisplay? metreDisplay,
    TonDefinition? tonDefinition,
    DensityUnit? densityUnit,
  }) {
    return CalculatorPreferences(
      system: system ?? this.system,
      fractionResolution: fractionResolution ?? this.fractionResolution,
      metreDisplay: metreDisplay ?? this.metreDisplay,
      tonDefinition: tonDefinition ?? this.tonDefinition,
      densityUnit: densityUnit ?? this.densityUnit,
    );
  }

  @override
  List<Object?> get props => [
    system,
    fractionResolution,
    metreDisplay,
    tonDefinition,
    densityUnit,
  ];
}
