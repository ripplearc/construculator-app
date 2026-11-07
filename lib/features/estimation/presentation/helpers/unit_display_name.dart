import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/material_unit_list.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

/// The localized name of a [Unit] as shown on cost forms.
extension UnitDisplayName on Unit {
  /// This unit's name in the language of [l10n], for example "Liters".
  String displayName(AppLocalizations l10n) => switch (this) {
    Unit.pieces => l10n.unitPieces,
    Unit.meters => l10n.unitMeters,
    Unit.squareMeters => l10n.unitSquareMeters,
    Unit.cubicMeters => l10n.unitCubicMeters,
    Unit.kilograms => l10n.unitKilograms,
    Unit.tons => l10n.unitTons,
    Unit.liters => l10n.unitLiters,
    Unit.hours => l10n.unitHours,
    Unit.days => l10n.unitDays,
    Unit.boxes => l10n.unitBoxes,
    Unit.bags => l10n.unitBags,
    Unit.rolls => l10n.unitRolls,
    Unit.sheets => l10n.unitSheets,
    Unit.feet => l10n.unitFeet,
    Unit.inches => l10n.unitInches,
    Unit.yards => l10n.unitYards,
    Unit.linearFeet => l10n.unitLinearFeet,
    Unit.squareFeet => l10n.unitSquareFeet,
    Unit.squareYards => l10n.unitSquareYards,
    Unit.squares => l10n.unitSquares,
    Unit.cubicFeet => l10n.unitCubicFeet,
    Unit.cubicYards => l10n.unitCubicYards,
    Unit.gallons => l10n.unitGallons,
    Unit.pounds => l10n.unitPounds,
    Unit.shortTons => l10n.unitShortTons,
    Unit.pairs => l10n.unitPairs,
    Unit.dozens => l10n.unitDozens,
    Unit.bundles => l10n.unitBundles,
    Unit.pallets => l10n.unitPallets,
    Unit.tubes => l10n.unitTubes,
  };

  /// The short symbol of this unit, such as `gal`, as in `$52.00 /gal` after
  /// a material rate.
  String symbol(AppLocalizations l10n) => switch (this) {
    Unit.pieces => l10n.unitSymbolPieces,
    Unit.meters => l10n.unitSymbolMeters,
    Unit.squareMeters => l10n.unitSymbolSquareMeters,
    Unit.cubicMeters => l10n.unitSymbolCubicMeters,
    Unit.kilograms => l10n.unitSymbolKilograms,
    Unit.tons => l10n.unitSymbolTons,
    Unit.liters => l10n.unitSymbolLiters,
    Unit.hours => l10n.unitSymbolHours,
    Unit.days => l10n.unitSymbolDays,
    Unit.boxes => l10n.unitSymbolBoxes,
    Unit.bags => l10n.unitSymbolBags,
    Unit.rolls => l10n.unitSymbolRolls,
    Unit.sheets => l10n.unitSymbolSheets,
    Unit.feet => l10n.unitSymbolFeet,
    Unit.inches => l10n.unitSymbolInches,
    Unit.yards => l10n.unitSymbolYards,
    Unit.linearFeet => l10n.unitSymbolLinearFeet,
    Unit.squareFeet => l10n.unitSymbolSquareFeet,
    Unit.squareYards => l10n.unitSymbolSquareYards,
    Unit.squares => l10n.unitSymbolSquares,
    Unit.cubicFeet => l10n.unitSymbolCubicFeet,
    Unit.cubicYards => l10n.unitSymbolCubicYards,
    Unit.gallons => l10n.unitSymbolGallons,
    Unit.pounds => l10n.unitSymbolPounds,
    Unit.shortTons => l10n.unitSymbolShortTons,
    Unit.pairs => l10n.unitSymbolPairs,
    Unit.dozens => l10n.unitSymbolDozens,
    Unit.bundles => l10n.unitSymbolBundles,
    Unit.pallets => l10n.unitSymbolPallets,
    Unit.tubes => l10n.unitSymbolTubes,
  };
}

/// The localized heading of a [UnitGroup] in the unit list.
extension UnitGroupHeading on UnitGroup {
  /// This group's heading in the language of [l10n], for example "By area".
  String heading(AppLocalizations l10n) => switch (this) {
    UnitGroup.length => l10n.unitGroupLength,
    UnitGroup.area => l10n.unitGroupArea,
    UnitGroup.volume => l10n.unitGroupVolume,
    UnitGroup.weight => l10n.unitGroupWeight,
    UnitGroup.count => l10n.unitGroupCount,
    UnitGroup.packaging => l10n.unitGroupPackaging,
  };
}
