import 'package:construculator/libraries/calculator_engine/models/calculator_preferences.dart';
import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:equatable/equatable.dart';

/// The three stores that hold a width and a height (UX Design Doc term
/// 2.16): drywall sheets, masonry pieces, footing cross-sections.
enum SizeStore {
  /// Drywall sheet sizes the [Drywal] key counts sheets by.
  sheet,

  /// Masonry piece sizes the [Msnry] key counts pieces by.
  masonry,

  /// Footing cross-sections the [Footng] key computes volume by.
  footing,
}

/// A stored width × height (48in x 96in), kept in ticks so a sheet count
/// and a computed area agree to the tick.
class StoredSize extends Equatable {
  /// The row's id, `null` until it is stored.
  final String? id;

  /// Which store the size belongs to.
  final SizeStore store;

  /// The unit system whose seed set the size belongs to (Appendix B seeds
  /// sheet sizes per system).
  final MeasurementSystem system;

  /// The width.
  final Length width;

  /// The height.
  final Length height;

  /// The user's order within the store, from zero.
  final int position;

  const StoredSize({
    this.id,
    required this.store,
    required this.system,
    required this.width,
    required this.height,
    required this.position,
  });

  /// Returns a copy with the given fields replaced.
  StoredSize copyWith({
    String? id,
    SizeStore? store,
    MeasurementSystem? system,
    Length? width,
    Length? height,
    int? position,
  }) => StoredSize(
    id: id ?? this.id,
    store: store ?? this.store,
    system: system ?? this.system,
    width: width ?? this.width,
    height: height ?? this.height,
    position: position ?? this.position,
  );

  @override
  List<Object?> get props => [id, store, system, width, height, position];
}

/// An on-centre spacing the [Qty@OC] key offers (16in, 24in).
class StoredSpacing extends Equatable {
  /// The row's id, `null` until it is stored.
  final String? id;

  /// The spacing.
  final Length spacing;

  /// The user's order, from zero.
  final int position;

  const StoredSpacing({this.id, required this.spacing, required this.position});

  /// Returns a copy with the given fields replaced.
  StoredSpacing copyWith({String? id, Length? spacing, int? position}) =>
      StoredSpacing(
        id: id ?? this.id,
        spacing: spacing ?? this.spacing,
        position: position ?? this.position,
      );

  @override
  List<Object?> get props => [id, spacing, position];
}

/// The fence's post spacing and rails per section (Appendix B: O.C. 8ft,
/// 3 rails).
class FenceConfiguration extends Equatable {
  /// The post spacing.
  final Length onCentre;

  /// Rails between two posts.
  final int railsPerSection;

  const FenceConfiguration({
    required this.onCentre,
    required this.railsPerSection,
  });

  /// Returns a copy with the given fields replaced.
  FenceConfiguration copyWith({Length? onCentre, int? railsPerSection}) =>
      FenceConfiguration(
        onCentre: onCentre ?? this.onCentre,
        railsPerSection: railsPerSection ?? this.railsPerSection,
      );

  @override
  List<Object?> get props => [onCentre, railsPerSection];
}

/// The units a rate is stored per (Section 9, "Cost").
enum RateUnit {
  /// $/ft²
  squareFoot,

  /// $/yd²
  squareYard,

  /// $/m²
  squareMetre,

  /// $/in²
  squareInch,

  /// $/ft³
  cubicFoot,

  /// $/yd³
  cubicYard,

  /// $/m³
  cubicMetre,

  /// $ per sheet
  sheet,

  /// $ per 1,000 board feet, how lumber is priced.
  thousandBoardFeet,
}

/// A rate per unit and the waste factor the Waste pill set for it.
class StoredRate extends Equatable {
  /// The unit the rate is per.
  final RateUnit unit;

  /// The rate in the user's currency.
  final double rate;

  /// The waste factor in percent; zero until the Waste pill is edited.
  final double wastePercent;

  const StoredRate({
    required this.unit,
    required this.rate,
    this.wastePercent = 0,
  });

  /// Returns a copy with the given fields replaced.
  StoredRate copyWith({RateUnit? unit, double? rate, double? wastePercent}) =>
      StoredRate(
        unit: unit ?? this.unit,
        rate: rate ?? this.rate,
        wastePercent: wastePercent ?? this.wastePercent,
      );

  @override
  List<Object?> get props => [unit, rate, wastePercent];
}

/// A named material density in lbs/yd³ (concrete 4,050…).
class StoredDensity extends Equatable {
  /// The row's id, `null` until it is stored.
  final String? id;

  /// The material's name as the user typed it.
  final String name;

  /// The density in pounds per cubic yard, the stored unit whatever the
  /// display setting.
  final double poundsPerCubicYard;

  /// The user's order, from zero.
  final int position;

  const StoredDensity({
    this.id,
    required this.name,
    required this.poundsPerCubicYard,
    required this.position,
  });

  /// Returns a copy with the given fields replaced.
  StoredDensity copyWith({
    String? id,
    String? name,
    double? poundsPerCubicYard,
    int? position,
  }) => StoredDensity(
    id: id ?? this.id,
    name: name ?? this.name,
    poundsPerCubicYard: poundsPerCubicYard ?? this.poundsPerCubicYard,
    position: position ?? this.position,
  );

  @override
  List<Object?> get props => [id, name, poundsPerCubicYard, position];
}
