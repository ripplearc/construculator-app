import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

/// Returns the localized display name for [unit] using [l10n].
String unitDisplayName(Unit unit, AppLocalizations l10n) => switch (unit) {
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
