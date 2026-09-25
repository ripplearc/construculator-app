part of 'your_rates_bloc.dart';

/// Base sealed class for all "Your rates" events.
sealed class YourRatesEvent {
  const YourRatesEvent();
}

/// Fired to (re)load the recents list for one [category]: the last
/// [_recentsLimit] entries by [YourRateEntry.savedAt].
class YourRatesRefreshRecents extends YourRatesEvent {
  const YourRatesRefreshRecents(this.category);
  final CostItemType category;
}

/// Fired when the user searches by item name, optionally scoped to one
/// [category]. An empty [query] returns every matching entry.
class YourRatesSearched extends YourRatesEvent {
  const YourRatesSearched(this.query, {this.category});
  final String query;
  final CostItemType? category;
}
