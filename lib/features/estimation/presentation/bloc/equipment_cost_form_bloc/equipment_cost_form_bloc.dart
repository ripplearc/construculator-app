import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'equipment_cost_form_event.dart';
part 'equipment_cost_form_state.dart';

/// Inclusive bounds for a manually entered daily rate or job amount.
const double _minRate = 0.01;
const double _maxRate = 999999.99;

/// BLoC for managing the equipment cost form: item type, Day/Job pricing,
/// delivery fee, validation, and submission to [CostItemRepository].
class EquipmentCostFormBloc
    extends Bloc<EquipmentCostFormEvent, EquipmentCostFormState> {
  final CostItemRepository _repository;
  final Clock _clock;

  EquipmentCostFormBloc({
    required CostItemRepository repository,
    required Clock clock,
  }) : _repository = repository,
       _clock = clock,
       super(const EquipmentCostFormInitial()) {
    on<EquipmentCostItemTypeChanged>(
      (e, emit) => _emit(emit, (d) => d.copyWith(equipmentType: e.value)),
    );
    on<EquipmentMethodSwitchedEvent>((e, emit) {
      _emit(emit, (d) {
        final rate = e.method == EquipmentPricingMethod.day
            ? d.dailyRate
            : d.jobAmount;
        return d.copyWith(
          method: e.method,
          rateStatus: rate == null
              ? RateStatus.missing
              : RateStatus.ownRateConfirmed,
        );
      });
    });
    on<EquipmentDurationUpdatedEvent>(
      (e, emit) =>
          _emit(emit, (d) => d.copyWith(duration: double.tryParse(e.value))),
    );
    on<EquipmentRateUpdatedEvent>((e, emit) {
      final rate = double.tryParse(e.value);
      // A manually typed rate is the user's own, not a sampled catalog rate,
      // so it's confirmed as soon as it parses. There is no lookup-a-rate
      // flow wired yet (CA-1145/CA-1151); a future catalog selection path
      // will need to set sampleRateUnverified instead before landing here.
      final rateStatus = rate == null
          ? RateStatus.missing
          : RateStatus.ownRateConfirmed;
      _emit(
        emit,
        (d) => d.method == EquipmentPricingMethod.day
            ? d.copyWith(dailyRate: rate, rateStatus: rateStatus)
            : d.copyWith(jobAmount: rate, rateStatus: rateStatus),
      );
    });
    on<EquipmentDeliveryFeeUpdatedEvent>((e, emit) {
      final fee = double.tryParse(e.value);
      _emit(
        emit,
        (d) => d.copyWith(
          deliveryFee: fee,
          deliveryFeeStatus: fee == null
              ? DeliveryFeeStatus.unset
              : DeliveryFeeStatus.estimated,
        ),
      );
    });
    on<EquipmentDeliveryFeeConfirmedEvent>((e, emit) {
      if (_current().deliveryFee == null) return;
      _emit(
        emit,
        (d) => d.copyWith(deliveryFeeStatus: DeliveryFeeStatus.confirmed),
      );
    });
    on<EquipmentDescriptionUpdatedEvent>((e, emit) {
      // Trimmed-empty is treated the same as "never typed" — description is
      // an optional free-text note, not a value with its own required/unset
      // distinction the way deliveryFee has (0 vs null).
      final description = e.value.trim().isEmpty ? null : e.value;
      _emit(emit, (d) => d.copyWith(description: description));
    });
    on<EquipmentCostSubmittedEvent>(_onSubmitted);
    on<EquipmentOutsizedFeeAcceptedEvent>(_onOutsizedFeeAccepted);
  }

  void _emit(
    Emitter<EquipmentCostFormState> emit,
    EquipmentCostFormWithData Function(EquipmentCostFormWithData) update,
  ) {
    emit(EquipmentCostFormEditing(_validated(update(_current()))));
  }

  Future<void> _onSubmitted(
    EquipmentCostSubmittedEvent event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    final draft = _validated(_current());
    if (!draft.isValid) {
      emit(EquipmentCostFormEditing(draft));
      return;
    }
    await _submit(draft, event.estimateId, emit);
  }

  Future<void> _onOutsizedFeeAccepted(
    EquipmentOutsizedFeeAcceptedEvent event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    final current = state;
    if (current is! EquipmentCostFormOutsizedFeeConfirm) return;
    await _submit(current.data, event.estimateId, emit);
  }

  Future<void> _submit(
    EquipmentCostFormWithData draft,
    String estimateId,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    emit(EquipmentCostFormSubmitting(draft));
    final result = await _repository.createCostItem(
      _buildCostItem(draft, estimateId),
    );
    result.fold(
      (failure) => emit(EquipmentCostFormFailure(draft, failure)),
      (created) => emit(EquipmentCostFormSuccess(draft, created)),
    );
  }

  EquipmentCostFormWithData _current() {
    return switch (state) {
      EquipmentCostFormEditing(:final data) => data,
      EquipmentCostFormOutsizedFeeConfirm(:final data) => data,
      EquipmentCostFormSubmitting(:final data) => data,
      EquipmentCostFormSuccess(:final data) => data,
      EquipmentCostFormFailure(:final data) => data,
      EquipmentCostFormInitial() => const EquipmentCostFormWithData(),
    };
  }

  EquipmentCostFormWithData _validated(EquipmentCostFormWithData draft) {
    final errors = <String, String>{};
    if (draft.equipmentType.trim().isEmpty) {
      errors['itemType'] = 'itemTypeRequired';
    }
    if (draft.method == EquipmentPricingMethod.day) {
      final duration = draft.duration;
      if (duration == null || duration <= 0) {
        errors['duration'] = 'durationRequired';
      }
      _validateRate(draft.dailyRate, 'dailyRate', errors);
    } else {
      _validateRate(draft.jobAmount, 'jobAmount', errors);
    }
    return draft.copyWith(isValid: errors.isEmpty, fieldErrors: errors);
  }

  void _validateRate(double? rate, String field, Map<String, String> errors) {
    if (rate == null) {
      errors[field] = 'rateRequired';
    } else if (rate < _minRate || rate > _maxRate) {
      errors[field] = 'rateOutOfRange';
    }
  }

  EquipmentCostItem _buildCostItem(
    EquipmentCostFormWithData draft,
    String estimateId,
  ) {
    final now = _clock.now();
    final isDay = draft.method == EquipmentPricingMethod.day;
    final duration = draft.duration;
    final dailyRate = draft.dailyRate;
    final jobAmount = draft.jobAmount;
    final deliveryFee = draft.deliveryFee;
    final total = isDay
        ? (duration ?? 0) * (dailyRate ?? 0) + (deliveryFee ?? 0)
        : (jobAmount ?? 0) + (deliveryFee ?? 0);
    return EquipmentCostItem(
      id: '',
      estimateId: estimateId,
      itemName: draft.equipmentType,
      calculation: {
        if (isDay) 'dailyRate': dailyRate ?? 0,
        if (isDay) 'duration': duration ?? 0,
        if (!isDay) 'jobAmount': jobAmount ?? 0,
        if (deliveryFee != null) 'deliveryFee': deliveryFee,
      },
      itemTotalCost: total,
      createdAt: now,
      updatedAt: now,
      currency: 'USD',
      pricingMethod: draft.method,
      deliveryFeeStatus: draft.deliveryFeeStatus,
      rateStatus: draft.rateStatus,
      duration: isDay ? duration : null,
      dailyRate: isDay && dailyRate != null ? Money(amount: dailyRate) : null,
      jobAmount: !isDay && jobAmount != null ? Money(amount: jobAmount) : null,
      deliveryFee: deliveryFee != null ? Money(amount: deliveryFee) : null,
      description: draft.description,
    );
  }
}
