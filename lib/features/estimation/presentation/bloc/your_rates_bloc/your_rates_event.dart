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

/// Fired as the user types in a search box that sits above the recents list.
/// A blank [query] brings the recents back, the same as
/// [YourRatesRefreshRecents]; any other [query] searches like
/// [YourRatesSearched]. One event for both, so a search still waiting out its
/// debounce cannot land after the recents were asked for again.
class YourRatesRecentsQueried extends YourRatesEvent {
  const YourRatesRecentsQueried(this.query, this.category);
  final String query;
  final CostItemType category;
}

/// Fired to save [entry] via [YourRatesRepository.save]. Resolves to
/// [YourRatesSaveSucceeded], [YourRatesSaveCollision] (a label is needed),
/// [YourRatesSaveLabelTaken] (the label is already used), or
/// [YourRatesSaveFailed]. See [YourRatesRepository.save] for the rule.
class YourRatesSaveRequested extends YourRatesEvent {
  const YourRatesSaveRequested(this.entry);
  final YourRateEntry entry;
}
