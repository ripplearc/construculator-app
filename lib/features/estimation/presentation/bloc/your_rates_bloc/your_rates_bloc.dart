import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
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

EventTransformer<E> _ignoreWhileInFlight<E>() =>
    (events, mapper) => events.exhaustMap(mapper);

/// BLoC for the contractor's personal saved-rate book: recents per category
/// and free-text search, backed directly by [YourRatesRepository].
///
/// Deliberately has no usecase layer, matching `EquipmentCostFormBloc`'s
/// precedent for straightforward repository CRUD in this feature. Also has
/// no "current company"/"current project" dependency: every event carries
/// the category it operates within explicitly, and [YourRatesSaveRequested]
/// takes a fully-formed [YourRateEntry] whose [YourRateEntry.companyId] the
/// caller is responsible for supplying.
class YourRatesBloc extends Bloc<YourRatesEvent, YourRatesState> {
  final YourRatesRepository _repository;

  /// Debounce applied to a [YourRatesSearched] with a non-empty query. An empty
  /// query (every saved rate) runs at once. Defaults to
  /// [_kQueryDebounceDuration]; overridable so tests can pass [Duration.zero]
  /// instead of waiting out the real debounce window.
  YourRatesBloc({
    required this._repository,
    Duration queryDebounce = _kQueryDebounceDuration,
  }) : super(const YourRatesLoading()) {
    on<YourRatesRefreshRecents>(_onRefreshRecents, transformer: _restartable());
    on<YourRatesSearched>(
      _onSearched,
      transformer: _searchTransformer(queryDebounce),
    );
    on<YourRatesSaveRequested>(
      _onSaveRequested,
      transformer: _ignoreWhileInFlight(),
    );
  }

  Future<void> _onRefreshRecents(
    YourRatesRefreshRecents event,
    Emitter<YourRatesState> emit,
  ) async {
    final current = state;
    emit(
      current is YourRatesError
          ? YourRatesRetrying(current.failure)
          : const YourRatesLoading(),
    );
    final result = await _repository.search(
      '',
      category: event.category,
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
    final result = await _repository.search(
      event.query,
      category: event.category,
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
    final result = await _repository.save(event.entry);
    result.fold((failure) {
      final errorType = failure is EstimationFailure ? failure.errorType : null;
      switch (errorType) {
        case EstimationErrorType.duplicateEntry:
          emit(YourRatesSaveCollision(event.entry));
        case EstimationErrorType.duplicateLabel:
          emit(YourRatesSaveLabelTaken(event.entry));
        default:
          emit(YourRatesSaveFailed(failure));
      }
    }, (_) => emit(YourRatesSaveSucceeded()));
  }
}
