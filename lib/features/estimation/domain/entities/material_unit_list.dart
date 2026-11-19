import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';

/// What the units under one heading of the unit list measure.
enum UnitMeasure { length, area, volume, weight, count, packaging }

/// One heading of the unit list and its units, in the order they are shown.
class UnitListGroup {
  const UnitListGroup(this.measure, this.units);

  /// What the [units] measure.
  final UnitMeasure measure;

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
  UnitListGroup(UnitMeasure.length, [
    Unit.feet,
    Unit.inches,
    Unit.yards,
    Unit.linearFeet,
  ]),
  UnitListGroup(UnitMeasure.area, [
    Unit.squareFeet,
    Unit.squareYards,
    Unit.squares,
  ]),
  UnitListGroup(UnitMeasure.volume, [
    Unit.cubicFeet,
    Unit.cubicYards,
    Unit.gallons,
  ]),
  UnitListGroup(UnitMeasure.weight, [
    Unit.pounds,
    Unit.kilograms,
    Unit.shortTons,
  ]),
  UnitListGroup(UnitMeasure.count, [Unit.pieces, Unit.pairs, Unit.dozens]),
  UnitListGroup(UnitMeasure.packaging, [
    Unit.bags,
    Unit.boxes,
    Unit.rolls,
    Unit.sheets,
    Unit.bundles,
    Unit.pallets,
    Unit.tubes,
  ]),
];
