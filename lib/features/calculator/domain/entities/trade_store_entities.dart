import 'package:construculator/libraries/calculator_engine/models/quantity.dart';
import 'package:equatable/equatable.dart';

/// The three stores that hold a width and a height (UX Design Doc term
/// 2.16): drywall sheets, masonry pieces, footing cross-sections.
enum SizeStore {
  /// Drywall sheet sizes the `Drywal` key counts sheets by.
  sheet,

  /// Masonry piece sizes the `Msnry` key counts pieces by.
  masonry,

  /// Footing cross-sections the `Footng` key computes volume by.
  footing,
}

/// A stored width × height (48in x 96in), kept in ticks so a sheet count
/// and a computed area agree to the tick.
///
/// A size is one of Appendix B's defaults or one the user added. A default
/// has a [seed] and no [id] until the user changes it; a size the user added
/// has an [id] from the moment it is stored and no [seed]. Only the defaults
/// belong to one unit system: a size the user adds shows under Imperial and
/// Metric alike, in inches or in millimetres (term 2.16). Each length keeps
/// the unit it was spelled in, so a stored size reads back equal to itself.
class StoredSize extends Equatable {
  /// The row's id, `null` for a default the user has not changed.
  final String? id;

  /// Which store the size belongs to.
  final SizeStore store;

  /// The width.
  final Length width;

  /// The height.
  final Length height;

  /// The user's order within the store, from zero. The repository assigns
  /// it to a size the user adds: after the last one.
  final int position;

  /// The Appendix B default this size stands in for, `null` for one the
  /// user added.
  final String? seed;

  const StoredSize({
    this.id,
    required this.store,
    required this.width,
    required this.height,
    required this.position,
    this.seed,
  });

  /// Returns a copy with the given fields replaced.
  StoredSize copyWith({
    String? id,
    SizeStore? store,
    Length? width,
    Length? height,
    int? position,
    String? seed,
  }) => StoredSize(
    id: id ?? this.id,
    store: store ?? this.store,
    width: width ?? this.width,
    height: height ?? this.height,
    position: position ?? this.position,
    seed: seed ?? this.seed,
  );

  @override
  List<Object?> get props => [id, store, width, height, position, seed];
}

/// An on-centre spacing the `Qty@OC` key offers (16in, 24in).
class StoredSpacing extends Equatable {
  /// The row's id, `null` for a default the user has not changed.
  final String? id;

  /// The spacing.
  final Length spacing;

  /// The user's order, from zero; assigned by the repository to an added
  /// spacing.
  final int position;

  /// The Appendix B default this spacing stands in for, `null` for one the
  /// user added.
  final String? seed;

  const StoredSpacing({
    this.id,
    required this.spacing,
    required this.position,
    this.seed,
  });

  /// Returns a copy with the given fields replaced.
  StoredSpacing copyWith({
    String? id,
    Length? spacing,
    int? position,
    String? seed,
  }) => StoredSpacing(
    id: id ?? this.id,
    spacing: spacing ?? this.spacing,
    position: position ?? this.position,
    seed: seed ?? this.seed,
  );

  @override
  List<Object?> get props => [id, spacing, position, seed];
}

/// The fence's post spacing and rails per section (Appendix B: O.C. 8ft,
/// 3 rails). There is one, so it needs no id: the repository keeps the one
/// row the user's change is written to.
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

/// The units a cost is quoted per (Section 9, "Cost"): what a rate is per,
/// and what the Waste pill sets waste per. The rates themselves are the
/// company's saved rates since CA-1304 and are read through estimation; the
/// waste factor is the one cost fact that stays a trade store.
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

/// The waste factor the Waste pill set for one unit, in percent: 0% until
/// the pill is edited (Appendix B). One per [RateUnit], so it needs no id.
class StoredWaste extends Equatable {
  /// The unit the waste factor goes with.
  final RateUnit unit;

  /// The waste factor in percent.
  final double percent;

  const StoredWaste({required this.unit, this.percent = 0});

  /// Returns a copy with the given fields replaced.
  StoredWaste copyWith({RateUnit? unit, double? percent}) =>
      StoredWaste(unit: unit ?? this.unit, percent: percent ?? this.percent);

  @override
  List<Object?> get props => [unit, percent];
}

/// A named material density in lbs/yd³ (concrete 4,050…).
class StoredDensity extends Equatable {
  /// The row's id, `null` for a default the user has not changed.
  final String? id;

  /// The material's name as the user typed it.
  final String name;

  /// The density in pounds per cubic yard, the stored unit whatever the
  /// display setting.
  final double poundsPerCubicYard;

  /// The user's order, from zero; assigned by the repository to an added
  /// material.
  final int position;

  /// The Appendix B default this material stands in for, `null` for one the
  /// user added.
  final String? seed;

  const StoredDensity({
    this.id,
    required this.name,
    required this.poundsPerCubicYard,
    required this.position,
    this.seed,
  });

  /// Returns a copy with the given fields replaced.
  StoredDensity copyWith({
    String? id,
    String? name,
    double? poundsPerCubicYard,
    int? position,
    String? seed,
  }) => StoredDensity(
    id: id ?? this.id,
    name: name ?? this.name,
    poundsPerCubicYard: poundsPerCubicYard ?? this.poundsPerCubicYard,
    position: position ?? this.position,
    seed: seed ?? this.seed,
  );

  @override
  List<Object?> get props => [id, name, poundsPerCubicYard, position, seed];
}
