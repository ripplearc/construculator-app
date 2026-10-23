part of 'your_rates_bloc.dart';

/// Base sealed class for all "Your rates" events.
sealed class YourRatesEvent {
  const YourRatesEvent();
}

/// An event that reads the recents list or searches above it. All of them run
/// on one stream, so a newer one always cancels an older one that is still
/// waiting or running, and an old read cannot land over a newer result.
sealed class YourRatesRecentsEvent extends YourRatesEvent {
  const YourRatesRecentsEvent();

  /// The category the recents or the search belong to.
  CostItemType get category;
}

/// Fired to (re)load the recents list for one [category]: the last
/// [_recentsLimit] entries by [YourRateEntry.savedAt].
class YourRatesRefreshRecents extends YourRatesRecentsEvent {
  const YourRatesRefreshRecents(this.category);

  @override
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
/// [YourRatesSearched]. It shares one stream with [YourRatesRefreshRecents], so a
/// search still waiting out its debounce, or still running, cannot land after
/// the recents were asked for again, and the other way round.
class YourRatesRecentsQueried extends YourRatesRecentsEvent {
  const YourRatesRecentsQueried(
    this.query,
    this.category, {
    this.immediate = false,
  });
  final String query;

  /// Whether to skip the debounce. A retry after a failed read sets it, so the
  /// user's tap is answered at once instead of 300 ms later.
  final bool immediate;

  @override
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
