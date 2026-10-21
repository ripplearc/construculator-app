import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/presentation/helpers/unit_display_name.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';

/// Returns the localized display name for [unit] using [l10n].
String unitDisplayName(Unit unit, AppLocalizations l10n) =>
    unit.displayName(l10n);
