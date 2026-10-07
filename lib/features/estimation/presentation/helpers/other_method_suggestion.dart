import 'dart:math';

import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';

/// What the Look-up-a-rate sheet says when a search finds no saved rate under
/// the active pricing method but finds some under the other one (storyboard
/// CUJ 6, frame "A price on the other method").
///
/// [method] is the method the matches are saved under, so it is also the
/// method that the sheet's action switches to.
class OtherMethodSuggestion {
  /// The pricing method the matching rates are saved under.
  final EquipmentPricingMethod method;

  /// How many saved rates match the search under [method].
  final int count;

  /// The smallest amount among those rates.
  final double lowest;

  /// The largest amount among those rates.
  final double highest;

  const OtherMethodSuggestion._({
    required this.method,
    required this.count,
    required this.lowest,
    required this.highest,
  });

  /// The suggestion for [searchResults] while [active] is the selected
  /// method, or null when a rate under [active] matches or nothing matches
  /// under the other method.
  static OtherMethodSuggestion? from(
    List<YourRateEntry> searchResults, {
    required EquipmentPricingMethod active,
  }) {
    if (searchResults.any((entry) => entry.equipmentMethod == active)) {
      return null;
    }
    final other = searchResults
        .where((entry) => entry.equipmentMethod != null)
        .toList();
    if (other.isEmpty) return null;
    final amounts = other.map((entry) => entry.rate.amount);
    return OtherMethodSuggestion._(
      method: active == EquipmentPricingMethod.day
          ? EquipmentPricingMethod.job
          : EquipmentPricingMethod.day,
      count: other.length,
      lowest: amounts.reduce(min),
      highest: amounts.reduce(max),
    );
  }

  /// The line that replaces the rows, naming the typed [query] and the amount
  /// or the range found under [method].
  String message(AppLocalizations l10n, {required String query}) {
    final lowestText = DisplayFormatter.currency.format(lowest);
    final highestText = DisplayFormatter.currency.format(highest);
    return method == EquipmentPricingMethod.job
        ? l10n.yourRatesOtherMethodJobPrices(
            query,
            count,
            lowestText,
            highestText,
          )
        : l10n.yourRatesOtherMethodDayRates(
            query,
            count,
            lowestText,
            highestText,
          );
  }

  /// The words on the action that switches the sheet to [method].
  String actionLabel(AppLocalizations l10n) =>
      method == EquipmentPricingMethod.job
      ? l10n.yourRatesShowJobPrices
      : l10n.yourRatesShowDayRates;
}
