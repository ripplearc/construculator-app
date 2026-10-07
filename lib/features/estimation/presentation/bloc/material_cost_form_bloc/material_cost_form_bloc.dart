import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'material_cost_form_event.dart';
part 'material_cost_form_state.dart';

const double _minRate = 0.01;
const double _maxRate = 999999.99;
const double _quantityColumnLimit = 1e14;

/// BLoC for managing the material cost form: name, quantity, unit and rate,
/// and the validation that decides when Add is enabled.
class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  final LastUsedUnitRepository _lastUsedUnitRepository;

  MaterialCostFormBloc({required this._lastUsedUnitRepository})
    : super(const MaterialCostFormInitial()) {
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
    // TODO(CA-294): register MaterialCostFormSubmitted and wire to CostItemRepository.createCostItem
  }

  Future<void> _onStarted(
    MaterialCostFormStarted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    final unit = await _lastUsedUnitRepository.getLastUnit(
      CostItemType.material,
    );
    if (unit == null) return;
    _emit(emit, (d) => d.unit == null ? d.copyWith(unit: unit) : d);
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
    emit(MaterialCostFormEditing(_validated(update(_current()))));
  }

  MaterialCostFormData _current() {
    return switch (state) {
      MaterialCostFormEditing(:final data) => data,
      MaterialCostFormInitial() => const MaterialCostFormData(),
    };
  }

  MaterialCostFormData _validated(MaterialCostFormData draft) {
    final errors = <MaterialFormField, MaterialFieldError>{};
    final hasQuantity = _validateQuantity(draft.quantity, errors);
    final hasRate = _validateRate(draft.rate, errors);
    return draft.copyWith(
      isValid:
          draft.isItemNameValid && hasQuantity && draft.unit != null && hasRate,
      fieldErrors: errors,
    );
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
