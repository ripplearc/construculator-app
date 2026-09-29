import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'equipment_cost_form_event.dart';
part 'equipment_cost_form_state.dart';

/// Inclusive bounds for a manually entered daily rate, job amount, or
/// delivery fee. A delivery fee of exactly 0 is validated separately as a
/// distinct "confirmed free" state, not against this range.
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
        // A value preserved from before the switch can only have gotten here
        // by being typed (see EquipmentRateUpdatedEvent below), so it's
        // unconfirmed too — switching methods must never upgrade it to
        // ownRateConfirmed on its own.
        return d.copyWith(
          method: e.method,
          rateStatus: rate == null
              ? RateStatus.missing
              : RateStatus.ownRateUnconfirmed,
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
      // but typing it is not the same as confirming it: it only becomes
      // ownRateConfirmed through an explicit action (e.g. "save as my rate",
      // CA-1145/CA-1151), or by picking an already-confirmed rate from
      // Your Rates. A future catalog selection path will need to set
      // sampleRateUnverified instead before landing here.
      final rateStatus = rate == null
          ? RateStatus.missing
          : RateStatus.ownRateUnconfirmed;
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
      final current = _current();
      // Validated in _validated() below; a null or out-of-range delivery fee
      // (NaN/Infinity included, since those never populate fieldErrors as
      // "in range") must not be confirmable.
      if (current.deliveryFee == null ||
          current.fieldErrors.containsKey('deliveryFee')) {
        return;
      }
      _emit(
        emit,
        (d) => d.copyWith(deliveryFeeStatus: DeliveryFeeStatus.confirmed),
      );
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

  // Determines whether required fields are present (for isValid, which
  // gates the Add button) and builds fieldErrors for rendering.
  //
  // An empty/missing field is never added to fieldErrors: per product
  // decision, an empty field never renders a red error — the disabled Add
  // button already names what's missing, and on a phone, focus leaves a
  // field constantly during normal use, so a blur-triggered error there
  // would turn fields red during ordinary interaction. fieldErrors only
  // ever holds "a value was entered but it can't be used" messages (e.g. a
  // typed duration of 0), which the widget layer is expected to show on
  // blur and clear on the first valid keystroke.
  EquipmentCostFormWithData _validated(EquipmentCostFormWithData draft) {
    final errors = <String, String>{};
    final hasItemType = draft.equipmentType.trim().isNotEmpty;

    final bool hasDuration;
    final bool hasRate;
    if (draft.method == EquipmentPricingMethod.day) {
      hasDuration = _validateDuration(draft.duration, errors);
      hasRate = _validateRate(draft.dailyRate, 'dailyRate', errors);
    } else {
      hasDuration = true;
      hasRate = _validateRate(draft.jobAmount, 'jobAmount', errors);
    }
    final hasValidDeliveryFee = _validateDeliveryFee(draft.deliveryFee, errors);

    return draft.copyWith(
      isValid: hasItemType && hasDuration && hasRate && hasValidDeliveryFee,
      fieldErrors: errors,
    );
  }

  // Returns whether duration is present and a valid whole/half-day step
  // (0.5, 1, 1.5, 2, ...). A missing duration produces no errors entry; a
  // present-but-invalid one (not positive, not a half-day step, including
  // non-finite values) does.
  bool _validateDuration(double? duration, Map<String, String> errors) {
    if (duration == null) return false;
    final isValid =
        duration > 0 && duration.isFinite && _isHalfDayStep(duration);
    if (!isValid) {
      errors['duration'] = 'durationInvalid';
    }
    return isValid;
  }

  // Whether duration lands on a half-day step, i.e. duration * 2 is a
  // whole number. Only called for finite, positive durations.
  bool _isHalfDayStep(double duration) {
    final doubled = duration * 2;
    return (doubled - doubled.roundToDouble()).abs() < 1e-9;
  }

  // Returns whether rate is present and within _minRate.._maxRate. A
  // missing rate produces no errors entry; a present-but-out-of-range one
  // (NaN/Infinity included) does.
  bool _validateRate(double? rate, String field, Map<String, String> errors) {
    if (rate == null) return false;
    final inRange =
        !rate.isNaN && !rate.isInfinite && rate >= _minRate && rate <= _maxRate;
    if (!inRange) {
      errors[field] = 'rateOutOfRange';
    }
    return inRange;
  }

  // Returns whether fee is a valid delivery fee: unset (optional, so
  // valid), exactly 0 (a distinct "confirmed-free" state, not subject to
  // _minRate), or within _minRate.._maxRate. NaN/Infinity are always
  // rejected explicitly, since a NaN comparison against the range is always
  // false and would otherwise silently pass.
  bool _validateDeliveryFee(double? fee, Map<String, String> errors) {
    if (fee == null) return true;
    final isFree = fee == 0;
    final inRange =
        !fee.isNaN && !fee.isInfinite && fee >= _minRate && fee <= _maxRate;
    final isValid = isFree || inRange;
    if (!isValid) {
      errors['deliveryFee'] = 'deliveryFeeOutOfRange';
    }
    return isValid;
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
