import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'material_cost_form_event.dart';
part 'material_cost_form_state.dart';

const double _minRate = 0.01;
const double _maxRate = 999999.99;
const double _quantityColumnLimit = 1e14;
const double _lineTotalColumnLimit = 1e16;

/// BLoC for managing the material cost form: name, quantity, unit and rate,
/// and the validation that decides when Add is enabled.
class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  final CostItemRepository _repository;
  final LastUsedUnitRepository _lastUsedUnitRepository;
  final Clock _clock;

  /// The values the form opened with, to tell when the user has changed any.
  MaterialCostFormData _opened = const MaterialCostFormData();

  MaterialCostFormBloc({
    required this._repository,
    required this._lastUsedUnitRepository,
    required this._clock,
  }) : super(const MaterialCostFormInitial()) {
    on<MaterialCostFormStarted>(_onStarted);
    on<MaterialCostItemTypeChanged>(
      (e, emit) => _emit(emit, (d) => d.copyWith(itemName: e.value)),
    );
    on<MaterialQuantityUpdated>(
      (e, emit) =>
          _emit(emit, (d) => d.copyWith(quantity: double.tryParse(e.value))),
    );
    on<MaterialUnitSelected>(
      (e, emit) => _emit(emit, (d) => d.copyWith(unit: e.unit)),
    );
    on<MaterialRateUpdated>(_onRateUpdated);
    on<MaterialCostFormSubmitted>(_onSubmitted);
  }

  Future<void> _onStarted(
    MaterialCostFormStarted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    final rememberedUnit = await _lastUsedUnitRepository.getLastUnit(
      CostItemType.material,
    );
    _opened = MaterialCostFormData(unit: rememberedUnit);
    if (rememberedUnit != null && _current().unit == null) {
      _emit(emit, (d) => d.copyWith(unit: rememberedUnit));
    }
  }

  void _onRateUpdated(
    MaterialRateUpdated event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final rate = double.tryParse(event.value);
    _emit(
      emit,
      (d) => d.copyWith(
        rate: rate,
        rateStatus: rate == null
            ? RateStatus.missing
            : RateStatus.ownRateConfirmed,
      ),
    );
  }

  void _emit(
    Emitter<MaterialCostFormState> emit,
    MaterialCostFormData Function(MaterialCostFormData) update,
  ) {
    if (state is MaterialCostFormSubmitting ||
        state is MaterialCostFormSuccess) {
      return;
    }
    final updated = _validated(update(_current()));
    emit(
      MaterialCostFormEditing(
        updated.copyWith(hasUnsavedChanges: _differsFromOpened(updated)),
      ),
    );
  }

  Future<void> _onSubmitted(
    MaterialCostFormSubmitted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    if (state is MaterialCostFormSubmitting ||
        state is MaterialCostFormSuccess) {
      return;
    }
    final draft = _validated(_current());
    final quantity = draft.quantity;
    final rate = draft.rate;
    final unit = draft.unit;
    if (!draft.isValid || quantity == null || rate == null || unit == null) {
      emit(MaterialCostFormEditing(draft));
      return;
    }
    emit(MaterialCostFormSubmitting(draft));
    final result = await _repository.createCostItem(
      _buildCostItem(
        draft,
        event.estimateId,
        quantity: quantity,
        rate: rate,
        unit: unit,
      ),
    );
    await result.fold(
      (failure) async => emit(MaterialCostFormFailure(draft, failure)),
      (created) async {
        await _lastUsedUnitRepository.saveLastUnit(CostItemType.material, unit);
        emit(MaterialCostFormSuccess(draft, created));
      },
    );
  }

  MaterialCostItem _buildCostItem(
    MaterialCostFormData draft,
    String estimateId, {
    required double quantity,
    required double rate,
    required Unit unit,
  }) {
    final now = _clock.now();
    return MaterialCostItem(
      id: '',
      estimateId: estimateId,
      itemName: draft.itemName.trim(),
      calculation: {'unit_price': rate, 'quantity': quantity},
      itemTotalCost: draft.lineTotal,
      createdAt: now,
      updatedAt: now,
      // TODO: [CA-1223] no multi-currency support yet. https://ripplearc.youtrack.cloud/issue/CA-1223
      currency: 'USD',
      unitPrice: Money(amount: rate),
      quantity: Quantity(value: quantity, unit: unit),
      rateStatus: draft.rateStatus,
      quantityProvenance: QuantityProvenance.manual,
    );
  }

  bool _differsFromOpened(MaterialCostFormData data) =>
      data.itemName != _opened.itemName ||
      data.quantity != _opened.quantity ||
      data.unit != _opened.unit ||
      data.rate != _opened.rate;

  MaterialCostFormData _current() {
    return switch (state) {
      MaterialCostFormEditing(:final data) => data,
      MaterialCostFormSubmitting(:final data) => data,
      MaterialCostFormSuccess(:final data) => data,
      MaterialCostFormFailure(:final data) => data,
      MaterialCostFormInitial() => const MaterialCostFormData(),
    };
  }

  MaterialCostFormData _validated(MaterialCostFormData draft) {
    final errors = <MaterialFormField, MaterialFieldError>{};
    final hasQuantity = _validateQuantity(draft.quantity, errors);
    final hasRate = _validateRate(draft.rate, errors);
    final fitsLineTotal = switch ((
      hasQuantity,
      hasRate,
      draft.quantity,
      draft.rate,
    )) {
      (true, true, final quantity?, final rate?) => _validateLineTotal(
        quantity,
        rate,
        errors,
      ),
      _ => true,
    };
    return draft.copyWith(
      isValid:
          draft.isItemNameValid &&
          hasQuantity &&
          draft.unit != null &&
          hasRate &&
          fitsLineTotal,
      fieldErrors: errors,
    );
  }

  bool _validateLineTotal(
    double quantity,
    double rate,
    Map<MaterialFormField, MaterialFieldError> errors,
  ) {
    if (quantity * rate < _lineTotalColumnLimit) return true;
    errors[MaterialFormField.quantity] = MaterialFieldError.quantityTooLarge;
    return false;
  }

  bool _validateQuantity(
    double? quantity,
    Map<MaterialFormField, MaterialFieldError> errors,
  ) {
    if (quantity == null) return false;
    if (!(quantity > 0 && quantity.isFinite)) {
      errors[MaterialFormField.quantity] =
          MaterialFieldError.quantityNotPositive;
      return false;
    }
    if (quantity >= _quantityColumnLimit) {
      errors[MaterialFormField.quantity] = MaterialFieldError.quantityTooLarge;
      return false;
    }
    return true;
  }

  bool _validateRate(
    double? rate,
    Map<MaterialFormField, MaterialFieldError> errors,
  ) {
    if (rate == null) return false;
    final inRange =
        !rate.isNaN && !rate.isInfinite && rate >= _minRate && rate <= _maxRate;
    if (!inRange) {
      errors[MaterialFormField.rate] = MaterialFieldError.rateOutOfRange;
    }
    return inRange;
  }
}
