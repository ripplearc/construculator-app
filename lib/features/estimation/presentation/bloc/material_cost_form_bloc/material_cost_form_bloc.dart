import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/last_used_unit_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/identifiers/interfaces/id_generator.dart';
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
///
/// Add saves the line on the phone and finishes without waiting for the
/// server. The line gets its id when the form opens and keeps it through every
/// retry, so a line the server already has is updated and never added twice.
class MaterialCostFormBloc
    extends Bloc<MaterialCostFormEvent, MaterialCostFormState> {
  final CostItemRepository _repository;
  final LastUsedUnitRepository _lastUsedUnitRepository;
  final YourRatesRepository _yourRatesRepository;
  final Clock _clock;
  final String _lineId;

  MaterialCostFormData _formValuesAtOpening = const MaterialCostFormData();
  RememberedUnits _rememberedUnits = RememberedUnits.none;
  bool _unitPicked = false;

  MaterialCostFormBloc({
    required this._repository,
    required this._lastUsedUnitRepository,
    required this._yourRatesRepository,
    required this._clock,
    required IdGenerator idGenerator,
  }) : _lineId = idGenerator.newId(),
       super(const MaterialCostFormInitial()) {
    on<MaterialCostFormStarted>(_onStarted);
    on<MaterialSavedRateRecalled>(_onSavedRateRecalled);
    on<MaterialNamePrefilled>(_onNamePrefilled);
    on<MaterialCostItemTypeChanged>(
      (e, emit) => _emit(
        emit,
        (d) => _withRememberedUnit(
          d.copyWith(itemName: e.value, recalledRateId: null),
        ),
      ),
    );
    on<MaterialQuantityUpdated>(
      (e, emit) =>
          _emit(emit, (d) => d.copyWith(quantity: double.tryParse(e.value))),
    );
    on<MaterialUnitSelected>((e, emit) {
      _unitPicked = true;
      _emit(emit, (d) => _withPickedUnit(d, e.unit));
    });
    on<MaterialRateUpdated>(_onRateUpdated);
    on<MaterialWasteUpdated>(_onWasteUpdated);
    on<MaterialNoteUpdated>(
      (e, emit) => _emit(
        emit,
        (d) => d.copyWith(note: e.value.trim().isEmpty ? null : e.value),
      ),
    );
    on<MaterialPriceAttached>((e, emit) {
      _unitPicked = true;
      _emit(
        emit,
        (d) => d.copyWith(
          rate: e.rate,
          rateStatus: e.rateStatus,
          attachedPrice: e.price,
          unit: e.price.buyUnit,
        ),
      );
    });
    on<MaterialCostFormSubmitted>(_onSubmitted);
    on<MaterialCostEditOpened>(_onEditOpened);
    on<MaterialCostDeleteRequested>(_onDeleteRequested);
  }

  void _onEditOpened(
    MaterialCostEditOpened event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final item = event.item;
    final opened = _validated(
      MaterialCostFormData(
        itemName: item.itemName,
        quantity: item.quantity.value,
        unit: item.quantity.unit,
        rate: item.unitPrice.amount,
        rateStatus: item.rateStatus,
        wastePercent: item.wastePercent,
        note: item.description,
        editedItem: item,
      ),
    );
    _formValuesAtOpening = opened;
    emit(MaterialCostFormEditing(opened));
  }

  Future<void> _onDeleteRequested(
    MaterialCostDeleteRequested event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    final draft = state.data;
    final edited = draft.editedItem;
    if (edited == null ||
        state is MaterialCostFormSubmitting ||
        state is MaterialCostFormSuccess ||
        state is MaterialCostFormDeleted) {
      return;
    }
    emit(MaterialCostFormSubmitting(draft));
    final result = await _repository.deleteCostItem(edited.id);
    emit(
      result.fold(
        (failure) =>
            MaterialCostFormFailure(draft, failure, whileDeleting: true),
        (_) => MaterialCostFormDeleted(draft),
      ),
    );
  }

  Future<void> _onStarted(
    MaterialCostFormStarted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    _rememberedUnits = await _lastUsedUnitRepository.getLastUnits(
      CostItemType.material,
    );
    if (_current().isEditingExistingLine) return;
    // A recalled rate brings its own unit, or none so the user picks one.
    if (_formValuesAtOpening.recalledRateId != null) return;
    final current = _current();
    if (_withRememberedUnit(current).unit != current.unit) {
      _emit(emit, _withRememberedUnit);
    }
    _formValuesAtOpening = _current();
  }

  MaterialCostFormData _withRememberedUnit(MaterialCostFormData data) {
    // A name change must not swap the unit under a number already entered.
    if (_keepsShownUnit(data)) return data;
    return data.copyWith(unit: _rememberedUnits.forItem(data.itemName));
  }

  bool _keepsShownUnit(MaterialCostFormData data) =>
      data.unit != null &&
      (_unitPicked || data.quantity != null || data.rate != null);

  MaterialCostFormData _withPickedUnit(MaterialCostFormData data, Unit unit) {
    final picked = data.copyWith(unit: unit);
    final price = data.attachedPrice;
    if (price == null || price.allows(unit)) return picked;
    return picked.copyWith(
      rate: null,
      rateStatus: RateStatus.missing,
      attachedPrice: null,
    );
  }

  void _onSavedRateRecalled(
    MaterialSavedRateRecalled event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final entry = event.entry;
    _emit(emit, (d) {
      final recalled = d.copyWith(
        itemName: entry.itemName,
        rate: entry.rate.amount,
        unit: entry.unit,
        rateStatus: RateStatus.ownRateConfirmed,
        recalledRateId: entry.id,
      );
      _formValuesAtOpening = recalled;
      return recalled;
    });
  }

  void _onNamePrefilled(
    MaterialNamePrefilled event,
    Emitter<MaterialCostFormState> emit,
  ) {
    _emit(emit, (d) {
      final prefilled = _withRememberedUnit(
        d.copyWith(itemName: event.name, recalledRateId: null),
      );
      _formValuesAtOpening = _formValuesAtOpening.copyWith(
        itemName: event.name,
        unit: prefilled.unit,
      );
      return prefilled;
    });
  }

  void _onRateUpdated(
    MaterialRateUpdated event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final rate = double.tryParse(event.value);
    _emit(emit, (d) {
      final stored = d.editedItem;
      return d.copyWith(
        rate: rate,
        rateStatus: switch (rate) {
          null => RateStatus.missing,
          _ when stored != null && rate == stored.unitPrice.amount =>
            stored.rateStatus,
          _ => RateStatus.ownRateUnconfirmed,
        },
        attachedPrice: null,
        recalledRateId: null,
      );
    });
  }

  void _onWasteUpdated(
    MaterialWasteUpdated event,
    Emitter<MaterialCostFormState> emit,
  ) {
    final waste = double.tryParse(event.value);
    if (waste != null &&
        !(waste >= 0 && waste <= MaterialCostFormData.maxWastePercent)) {
      return;
    }
    _emit(emit, (d) => d.copyWith(wastePercent: waste));
  }

  void _emit(
    Emitter<MaterialCostFormState> emit,
    MaterialCostFormData Function(MaterialCostFormData) update,
  ) {
    if (state is MaterialCostFormSubmitting ||
        state is MaterialCostFormSuccess ||
        state is MaterialCostFormDeleted) {
      return;
    }
    final updated = _validated(update(_current()));
    final next = updated.copyWith(
      hasUnsavedChanges: _differsFromOpened(updated),
    );
    emit(switch (state) {
      MaterialCostFormFailure(whileDeleting: false, :final failure) =>
        MaterialCostFormFailure(next, failure),
      _ => MaterialCostFormEditing(next),
    });
  }

  Future<void> _onSubmitted(
    MaterialCostFormSubmitted event,
    Emitter<MaterialCostFormState> emit,
  ) async {
    if (state is MaterialCostFormSubmitting ||
        state is MaterialCostFormSuccess ||
        state is MaterialCostFormDeleted) {
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
    final edited = draft.editedItem;
    final line = _buildCostItem(
      draft,
      event.estimateId,
      quantity: quantity,
      rate: rate,
      unit: unit,
      existing: edited,
    );
    final result = edited == null
        ? await _repository.addCostItemOnPhone(line)
        : await _repository.updateCostItem(line);
    await result.fold(
      (failure) async => emit(MaterialCostFormFailure(draft, failure)),
      (saved) async {
        if (edited == null) {
          await _lastUsedUnitRepository.saveLastUnit(
            CostItemType.material,
            draft.itemName,
            unit,
          );
        }
        if (draft.recalledRateId case final rateId?) {
          // The line is already added, so a failed record must not stop the
          // user. The rate then keeps its older "Used" date.
          await _yourRatesRepository.recordRateUse(rateId);
        }
        emit(MaterialCostFormSuccess(draft, saved));
      },
    );
  }

  MaterialCostItem _buildCostItem(
    MaterialCostFormData draft,
    String estimateId, {
    required double quantity,
    required double rate,
    required Unit unit,
    MaterialCostItem? existing,
  }) {
    final now = _clock.now().toUtc();
    return MaterialCostItem(
      id: existing?.id ?? _lineId,
      estimateId: estimateId,
      itemName: draft.itemName.trim(),
      calculation: {
        ...?existing?.calculation,
        'unit_price': rate,
        'quantity': quantity,
      },
      itemTotalCost: draft.lineTotal,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      // TODO: [CA-1223] no multi-currency support yet. https://ripplearc.youtrack.cloud/issue/CA-1223
      currency: 'USD',
      unitPrice: Money(amount: rate),
      quantity: Quantity(value: quantity, unit: unit),
      wastePercent: draft.wastePercent,
      rateStatus: draft.rateStatus,
      quantityProvenance:
          existing != null && quantity == existing.quantity.value
          ? existing.quantityProvenance
          : QuantityProvenance.manual,
      calculatorFormula: existing != null && quantity == existing.quantity.value
          ? existing.calculatorFormula
          : null,
      productLink: existing?.productLink,
      description: draft.note,
    );
  }

  bool _differsFromOpened(MaterialCostFormData data) =>
      data.itemName.trim() != _formValuesAtOpening.itemName.trim() ||
      data.quantity != _formValuesAtOpening.quantity ||
      data.unit != _formValuesAtOpening.unit ||
      data.rate != _formValuesAtOpening.rate ||
      data.wastePercent != _formValuesAtOpening.wastePercent ||
      data.note != _formValuesAtOpening.note;

  MaterialCostFormData _current() {
    return switch (state) {
      MaterialCostFormEditing(:final data) => data,
      MaterialCostFormSubmitting(:final data) => data,
      MaterialCostFormSuccess(:final data) => data,
      MaterialCostFormFailure(:final data) => data,
      MaterialCostFormDeleted(:final data) => data,
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
        quantity * (1 + (draft.wastePercent ?? 0) / 100),
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
