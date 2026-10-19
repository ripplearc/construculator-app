import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/estimation/domain/estimation_error_type.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'your_rates_event.dart';
part 'your_rates_state.dart';

const int _recentsLimit = 4;

const Duration _kQueryDebounceDuration = Duration(milliseconds: 300);

/// Waits [debounce] for a non-empty query and runs only the newest event. An
/// empty query waits a zero-length timer, so the event still runs a moment
/// after it was added.
EventTransformer<E> _debouncedSearch<E>(
  Duration debounce,
  String Function(E event) queryOf,
) =>
    (events, mapper) => events
        .debounce(
          (event) => TimerStream<void>(
            null,
            queryOf(event).isEmpty ? Duration.zero : debounce,
          ),
        )
        .switchMap(mapper);

/// Runs only the newest event. A blank query runs at once, with no timer, and
/// any other query waits [debounce] first. A newer event drops an older one
/// that is still waiting out its debounce or already running.
EventTransformer<E> _searchTransformer<E>(
  Duration debounce,
  String Function(E event) queryOf,
) =>
    (events, mapper) => events.switchMap(
      (event) => queryOf(event).isEmpty
          ? mapper(event)
          : TimerStream<void>(null, debounce).switchMap((_) => mapper(event)),
    );

EventTransformer<E> _ignoreWhileInFlight<E>() =>
    (events, mapper) => events.exhaustMap(mapper);

/// BLoC for the contractor's personal saved-rate book: recents per category
/// and free-text search, backed directly by [YourRatesRepository].
///
/// Deliberately has no usecase layer, matching `EquipmentCostFormBloc`'s
/// precedent for straightforward repository CRUD in this feature. Resolves
/// the caller's own company id itself via [CurrentCompanyResolver] rather
/// than trusting it from the caller: every event only carries the category
/// it operates within, and [YourRatesSaveRequested]'s [YourRateEntry] is a
/// draft whose [YourRateEntry.companyId] this bloc overwrites with the
/// resolved id before saving — the same throwaway-until-stamped treatment
/// [YourRateEntry.id] already gets for its server-assigned id.
///
/// A resolver result of `Right(null)` (no `company_users` row yet) is
/// treated as "zero saved rates" for recents/search, per
/// [CurrentCompanyResolver.resolve]'s own contract, and as
/// [YourRatesSaveNoCompany] for [YourRatesSaveRequested] — there is no
/// company to scope the write to.
class YourRatesBloc extends Bloc<YourRatesEvent, YourRatesState> {
  final YourRatesRepository _repository;
  final CurrentCompanyResolver _companyResolver;

  /// Debounce applied to a [YourRatesSearched] with a non-empty query, and to a
  /// [YourRatesRecentsQueried] with a query that is not blank. An empty query
  /// (every saved rate), a blank one and [YourRatesRefreshRecents] run at once.
  /// Defaults to [_kQueryDebounceDuration]; overridable so tests can pass
  /// [Duration.zero] instead of waiting out the real debounce window.
  YourRatesBloc({
    required this._repository,
    required this._companyResolver,
    Duration queryDebounce = _kQueryDebounceDuration,
  }) : super(const YourRatesLoading()) {
    on<YourRatesSearched>(
      _onSearched,
      transformer: _debouncedSearch(queryDebounce, (event) => event.query),
    );
    on<YourRatesRecentsEvent>(
      _onRecentsEvent,
      transformer: _searchTransformer(
        queryDebounce,
        (event) => switch (event) {
          YourRatesRecentsQueried(:final query) => query.trim(),
          YourRatesRefreshRecents() => '',
        },
      ),
    );
    on<YourRatesSaveRequested>(
      _onSaveRequested,
      transformer: _ignoreWhileInFlight(),
    );
  }

  Future<String?> _resolvedCompanyId({
    required void Function(Failure failure) onFailure,
    required void Function() onNoCompany,
  }) async {
    final result = await _companyResolver.resolve();
    final failure = result.getLeftOrNull();
    if (failure != null) {
      onFailure(failure);
      return null;
    }
    final companyId = result.getRightOrNull();
    if (companyId == null) onNoCompany();
    return companyId;
  }

  Future<void> _onRefreshRecents(
    YourRatesRefreshRecents event,
    Emitter<YourRatesState> emit,
  ) async {
    emit(
      state is YourRatesError
          ? const YourRatesRetrying()
          : const YourRatesLoading(),
    );
    final companyId = await _resolvedCompanyId(
      onFailure: (failure) => emit(YourRatesError(failure)),
      onNoCompany: () => emit(const YourRatesLoaded([])),
    );
    if (companyId == null) return;
    final result = await _repository.search(
      '',
      category: event.category,
      companyId: companyId,
      limit: _recentsLimit,
    );
    result.fold(
      (failure) => emit(YourRatesError(failure)),
      (entries) => emit(YourRatesLoaded(entries)),
    );
  }

  Future<void> _onSearched(
    YourRatesSearched event,
    Emitter<YourRatesState> emit,
  ) async {
    emit(const YourRatesLoading());
    final companyId = await _resolvedCompanyId(
      onFailure: (failure) => emit(YourRatesError(failure)),
      onNoCompany: () => emit(const YourRatesSearchResults([])),
    );
    if (companyId == null) return;
    final result = await _repository.search(
      event.query,
      category: event.category,
      companyId: companyId,
    );
    result.fold(
      (failure) => emit(YourRatesError(failure)),
      (entries) => emit(YourRatesSearchResults(entries)),
    );
  }

  Future<void> _onRecentsEvent(
    YourRatesRecentsEvent event,
    Emitter<YourRatesState> emit,
  ) {
    return switch (event) {
      YourRatesRefreshRecents() => _onRefreshRecents(event, emit),
      YourRatesRecentsQueried(:final query, :final category)
          when query.trim().isEmpty =>
        _onRefreshRecents(YourRatesRefreshRecents(category), emit),
      YourRatesRecentsQueried(:final query, :final category) => _onSearched(
        YourRatesSearched(query, category: category),
        emit,
      ),
    };
  }

  Future<void> _onSaveRequested(
    YourRatesSaveRequested event,
    Emitter<YourRatesState> emit,
  ) async {
    final companyId = await _resolvedCompanyId(
      onFailure: (failure) => emit(YourRatesSaveFailed(failure)),
      onNoCompany: () => emit(const YourRatesSaveNoCompany()),
    );
    if (companyId == null) return;
    final entry = event.entry.copyWith(companyId: companyId);
    final result = await _repository.save(entry);
    result.fold((failure) {
      final errorType = failure is EstimationFailure ? failure.errorType : null;
      switch (errorType) {
        case EstimationErrorType.duplicateEntry:
          emit(YourRatesSaveCollision(entry));
        case EstimationErrorType.duplicateLabel:
          emit(YourRatesSaveLabelTaken(entry));
        default:
          emit(YourRatesSaveFailed(failure));
      }
    }, (_) => emit(YourRatesSaveSucceeded()));
  }
}
