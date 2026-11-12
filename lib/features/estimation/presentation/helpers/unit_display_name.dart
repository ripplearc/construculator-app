import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
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
  };

  /// This unit's lowercase name for [count], for example "sheet" for 1 and
  /// "sheets" for 13.25, in the language of [l10n].
  String countName(AppLocalizations l10n, num count) => switch (this) {
    Unit.pieces => l10n.unitNamePieces(count),
    Unit.meters => l10n.unitNameMeters(count),
    Unit.squareMeters => l10n.unitNameSquareMeters(count),
    Unit.cubicMeters => l10n.unitNameCubicMeters(count),
    Unit.kilograms => l10n.unitNameKilograms(count),
    Unit.tons => l10n.unitNameTons(count),
    Unit.liters => l10n.unitNameLiters(count),
    Unit.hours => l10n.unitNameHours(count),
    Unit.days => l10n.unitNameDays(count),
    Unit.boxes => l10n.unitNameBoxes(count),
    Unit.bags => l10n.unitNameBags(count),
    Unit.rolls => l10n.unitNameRolls(count),
    Unit.sheets => l10n.unitNameSheets(count),
  };
}
