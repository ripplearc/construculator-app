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

/// State after [YourRatesSaveRequested] succeeds outright (no collision).
///
/// Not const on purpose: every success must be a new object, because bloc
/// skips an emit that equals the current state, and a second save in one form
/// would otherwise show nothing.
class YourRatesSaveSucceeded extends YourRatesState {
  YourRatesSaveSucceeded();
}

/// State after [YourRatesSaveRequested] is rejected because it collides
/// with an existing entry and needs a distinguishing [YourRateEntry.entryLabel]
/// — see [YourRatesRepository.save]'s collision rule. [entry] is the entry
/// that was attempted, with [YourRateEntry.companyId] already resolved, so a
/// retry only needs to add a label to it.
class YourRatesSaveCollision extends YourRatesState {
  const YourRatesSaveCollision(this.entry);
  final YourRateEntry entry;
}

/// State after a labeled [YourRatesSaveRequested] is rejected because the same
/// name and pricing method already have that label. Nothing was written, and
/// [entry] is the entry the caller submitted, so the user can pick another
/// label for it.
class YourRatesSaveLabelTaken extends YourRatesState {
  const YourRatesSaveLabelTaken(this.entry);
  final YourRateEntry entry;
}

/// State after [YourRatesSaveRequested] fails for any other reason.
class YourRatesSaveFailed extends YourRatesState {
  const YourRatesSaveFailed(this.failure);
  final Failure failure;
}

/// State after [YourRatesSaveRequested] when the signed-in user has no company
/// to save under. Separate from [YourRatesSaveFailed] because trying again can
/// never fix it.
class YourRatesSaveNoCompany extends YourRatesState {
  const YourRatesSaveNoCompany();
}
