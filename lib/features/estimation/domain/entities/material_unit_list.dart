import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';

/// What the units under one heading of the unit list measure.
enum UnitGroup { length, area, volume, weight, count, packaging }

/// One heading of the unit list and its units, in the order they are shown.
class UnitListGroup {
  const UnitListGroup(this.group, this.units);

  /// What the [units] measure.
  final UnitGroup group;

  /// The units under the heading, top to bottom.
  final List<Unit> units;
}

/// The 23 imperial units a Material line can be counted in, grouped and
/// ordered as the Select unit sheet shows them.
///
/// The list is fixed and compiled in, never fetched, so every quantity is in a
/// unit the app already knows how to price. A metric list would be a second
/// constant of this same shape.
const imperialMaterialUnits = [
  UnitListGroup(UnitGroup.length, [
    Unit.feet,
    Unit.inches,
    Unit.yards,
    Unit.linearFeet,
  ]),
  UnitListGroup(UnitGroup.area, [
    Unit.squareFeet,
    Unit.squareYards,
    Unit.squares,
  ]),
  UnitListGroup(UnitGroup.volume, [
    Unit.cubicFeet,
    Unit.cubicYards,
    Unit.gallons,
  ]),
  UnitListGroup(UnitGroup.weight, [
    Unit.pounds,
    Unit.kilograms,
    Unit.shortTons,
  ]),
  UnitListGroup(UnitGroup.count, [Unit.pieces, Unit.pairs, Unit.dozens]),
  UnitListGroup(UnitGroup.packaging, [
    Unit.bags,
    Unit.boxes,
    Unit.rolls,
    Unit.sheets,
    Unit.bundles,
    Unit.pallets,
    Unit.tubes,
  ]),
];
