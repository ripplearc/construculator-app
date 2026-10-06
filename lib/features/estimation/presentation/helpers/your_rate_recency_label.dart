import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/formatting/display_formatter.dart';

/// The words under a Your recents row.
extension YourRateRecencyLabel on YourRateEntry {
  static const _daysInWeek = 7;
  static const _daysInMonth = 30;

  /// How long ago this rate was last added to an estimate ("Used 3 days
  /// ago"), or saved when it never was ("Saved 3 days ago").
  ///
  /// Counts calendar days up to [now]: under 7 days reads today, yesterday or
  /// N days ago; under 30 days reads whole weeks, where one is "last week";
  /// from 30 days reads whole months, where one is "last month".
  String recencyLabel(AppLocalizations l10n, {required DateTime now}) {
    final days = DisplayFormatter.calendarDaysSince(recencyAt, now: now);
    final isUsed = lastUsedAt != null;
    if (days == 0) {
      return isUsed ? l10n.yourRatesUsedToday : l10n.yourRatesSavedToday;
    }
    if (days == 1) {
      return isUsed
          ? l10n.yourRatesUsedYesterday
          : l10n.yourRatesSavedYesterday;
    }
    if (days < _daysInWeek) {
      return isUsed
          ? l10n.yourRatesUsedDaysAgo(days)
          : l10n.yourRatesSavedDaysAgo(days);
    }
    if (days < _daysInMonth) {
      final weeks = days ~/ _daysInWeek;
      return isUsed
          ? l10n.yourRatesUsedWeeksAgo(weeks)
          : l10n.yourRatesSavedWeeksAgo(weeks);
    }
    final months = days ~/ _daysInMonth;
    return isUsed
        ? l10n.yourRatesUsedMonthsAgo(months)
        : l10n.yourRatesSavedMonthsAgo(months);
  }
}
