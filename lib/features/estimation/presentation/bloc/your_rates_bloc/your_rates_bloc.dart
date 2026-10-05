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

EventTransformer<E> _restartable<E>() =>
    (events, mapper) => events.switchMap(mapper);

EventTransformer<YourRatesSearched> _searchTransformer(Duration debounce) =>
    (events, mapper) => events
        .debounce(
          (event) => TimerStream<void>(
            null,
            event.query.isEmpty ? Duration.zero : debounce,
          ),
        )
        .switchMap(mapper);

EventTransformer<E> _droppable<E>() =>
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
/// [CurrentCompanyResolver.resolve]'s own contract, and as a save failure
/// for [YourRatesSaveRequested] — there is no company to scope the write to.
class YourRatesBloc extends Bloc<YourRatesEvent, YourRatesState> {
  final YourRatesRepository _repository;
  final CurrentCompanyResolver _companyResolver;

  /// Debounce applied to a [YourRatesSearched] with a non-empty query. An empty
  /// query (every saved rate) runs at once. Defaults to
  /// [_kQueryDebounceDuration]; overridable so tests can pass [Duration.zero]
  /// instead of waiting out the real debounce window.
  YourRatesBloc({
    required this._repository,
    required this._companyResolver,
    Duration queryDebounce = _kQueryDebounceDuration,
  }) : super(const YourRatesLoading()) {
    on<YourRatesRefreshRecents>(_onRefreshRecents, transformer: _restartable());
    on<YourRatesSearched>(
      _onSearched,
      transformer: _searchTransformer(queryDebounce),
    );
    on<YourRatesSaveRequested>(_onSaveRequested, transformer: _droppable());
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
    emit(const YourRatesLoading());
    // TODO: [CA-1249] show a failure state in the sheet; today YourRatesError reads as an empty list. https://ripplearc.youtrack.cloud/issue/CA-1249
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

  Future<void> _onSaveRequested(
    YourRatesSaveRequested event,
    Emitter<YourRatesState> emit,
  ) async {
    // TODO: [CA-1249] show a message that retrying cannot fix when the user has no company. https://ripplearc.youtrack.cloud/issue/CA-1249
    final companyId = await _resolvedCompanyId(
      onFailure: (failure) => emit(YourRatesSaveFailed(failure)),
      onNoCompany: () => emit(
        const YourRatesSaveFailed(
          EstimationFailure(errorType: EstimationErrorType.permissionDenied),
        ),
      ),
    );
    if (companyId == null) return;
    final entry = event.entry.copyWith(companyId: companyId);
    final result = await _repository.save(entry);
    result.fold((failure) {
      if (failure is EstimationFailure &&
          failure.errorType == EstimationErrorType.duplicateEntry) {
        emit(YourRatesSaveCollision(entry));
      } else {
        emit(YourRatesSaveFailed(failure));
      }
    }, (_) => emit(YourRatesSaveSucceeded()));
  }
}
