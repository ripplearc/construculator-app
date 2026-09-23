part of 'your_rates_bloc.dart';

/// Base sealed class for all "Your rates" states.
sealed class YourRatesState {
  const YourRatesState();
}

/// State while a recents load or search is in flight.
class YourRatesLoading extends YourRatesState {
  const YourRatesLoading();
}

/// State after [YourRatesRefreshRecents] succeeds: up to [_recentsLimit]
/// most-recently-saved entries for the requested category.
class YourRatesLoaded extends YourRatesState {
  const YourRatesLoaded(this.recents);
  final List<YourRateEntry> recents;
}

/// State after [YourRatesSearched] succeeds: every matching entry.
class YourRatesSearchResults extends YourRatesState {
  const YourRatesSearchResults(this.results);
  final List<YourRateEntry> results;
}

/// State when a recents load or search failed.
class YourRatesError extends YourRatesState {
  const YourRatesError(this.failure);
  final Failure failure;
}
