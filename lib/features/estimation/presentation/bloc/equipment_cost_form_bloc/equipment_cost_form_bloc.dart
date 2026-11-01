import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/refused_your_rate_entity.dart';
import 'package:construculator/features/estimation/domain/repositories/cost_item_repository.dart';
import 'package:construculator/features/estimation/domain/repositories/your_rates_repository.dart';
import 'package:construculator/libraries/company/domain/current_company_resolver.dart';
import 'package:construculator/libraries/either/interfaces/either.dart';
import 'package:construculator/libraries/errors/failures.dart';
import 'package:construculator/libraries/powersync/models/your_rate_refusal_key.dart';
import 'package:construculator/libraries/time/interfaces/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

part 'equipment_cost_form_event.dart';
part 'equipment_cost_form_state.dart';

const double _minRate = 0.01;

/// The largest dollar amount an equipment cost field accepts (a rate or a
/// delivery fee).
const double largestMoneyAmount = 999999.99;
const double _durationColumnMax = 99999999.99;

/// BLoC for managing the equipment cost form: item type, Day/Job pricing,
/// delivery fee, validation, and submission to [CostItemRepository]. A line
/// added with a saved rate records a use of that rate in [YourRatesRepository].
class EquipmentCostFormBloc
    extends Bloc<EquipmentCostFormEvent, EquipmentCostFormState> {
  final CostItemRepository _repository;
  final YourRatesRepository _yourRatesRepository;
  final CurrentCompanyResolver _companyResolver;
  final Clock _clock;
  EquipmentCostFormData _formValuesAtOpening = const EquipmentCostFormData();

  String? _watchedRefusalKey;
  String? _companyId;

  // Notices this form already marked as shown, by item, so the notice stays
  // on screen when the watch reports the refusal as shown.
  final Map<String, RefusedDefaultNotice> _shownNotices = {};

  EquipmentCostFormBloc({
    required this._repository,
    required this._yourRatesRepository,
    required this._companyResolver,
    required this._clock,
  }) : super(const EquipmentCostFormInitial()) {
    on<EquipmentCostItemTypeChanged>((e, emit) {
      _emit(
        emit,
        (d) => d.copyWith(
          equipmentType: e.value,
          recalledRateId: e.value == d.equipmentType ? d.recalledRateId : null,
          recalledRateMethod: e.value == d.equipmentType
              ? d.recalledRateMethod
              : null,
        ),
      );
      _watchRefusalOf(e.value, state.formData.method);
    });
    on<EquipmentRefusalWatchRequested>(
      _onRefusalWatchRequested,
      transformer: (events, mapper) => events.switchMap(mapper),
    );
    on<EquipmentRefusalNoticeLookedUp>(
      _onRefusalNoticeLookedUp,
      transformer: (events, mapper) => events.switchMap(mapper),
    );
    on<EquipmentRefusalNoticeSeen>(_onRefusalNoticeSeen);
    on<EquipmentMethodSwitchedEvent>((e, emit) {
      _watchRefusalOf(state.formData.equipmentType, e.method);
      _emit(emit, (d) {
        if (e.method == d.method) return d;
        return d.copyWith(
          method: e.method,
          rateStatus: d.otherMethodRateStatus,
          otherMethodRateStatus: d.rateStatus,
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
    on<EquipmentSavedRateRecalledEvent>((e, emit) {
      _watchRefusalOf(state.formData.equipmentType, e.method);
      _emit(emit, (d) {
        final recalled = d.copyWith(
          method: e.method,
          rateStatus: RateStatus.ownRateConfirmed,
          otherMethodRateStatus: e.method == d.method
              ? d.otherMethodRateStatus
              : d.rateStatus,
          recalledRateId: e.rateId,
          recalledRateMethod: e.method,
          recalledFromRecents: e.fromRecents,
          recalledRate: e.fromRecents ? e.rate : d.recalledRate,
        );
        final withRate = e.method == EquipmentPricingMethod.day
            ? recalled.copyWith(dailyRate: e.rate)
            : recalled.copyWith(jobAmount: e.rate);
        if (e.fromRecents) _formValuesAtOpening = withRate;
        return withRate;
      });
    });
    on<EquipmentRecalledAmountSavedEvent>((e, emit) {
      _emit(
        emit,
        (d) =>
            d.recalledFromRecents ? d.copyWith(recalledRate: d.jobAmount) : d,
      );
    });
    on<EquipmentDeliveryFeeUpdatedEvent>((e, emit) {
      final fee = double.tryParse(e.value);
      final usable =
          fee != null && fee.isFinite && fee >= 0 && fee <= largestMoneyAmount;
      // Empty text clears the fee. A value that cannot be kept is ignored,
      // and the delivery field stops the key before it gets here.
      if (e.value.isNotEmpty && !usable) return;
      _emit(emit, (d) => d.copyWith(deliveryFee: fee));
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
    on<EquipmentOutsizedFeeDeclinedEvent>(_onOutsizedFeeDeclined);
  }

  // Starts watching the refusal of the item unless the item and method are the
  // ones already watched: a restart would lose a notice that was shown.
  void _watchRefusalOf(String itemName, EquipmentPricingMethod method) {
    final key =
        '${YourRateRefusalKey.normalizeName(itemName)}|${method.toJson()}';
    if (key == _watchedRefusalKey) return;
    _watchedRefusalKey = key;
    add(EquipmentRefusalWatchRequested(itemName: itemName, method: method));
  }

  Future<void> _onRefusalWatchRequested(
    EquipmentRefusalWatchRequested event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    if (event.itemName.trim().isEmpty) {
      emit(_stateWithNotice(null));
      return;
    }
    final companyId = await _resolveCompanyId();
    if (companyId == null) {
      emit(_stateWithNotice(null));
      return;
    }
    final shownKey = _shownKeyOf(event.itemName, event.method);
    await emit.forEach<Either<Failure, RefusedYourRate?>>(
      _yourRatesRepository.watchUnshownRefusal(
        companyId: companyId,
        category: CostItemType.equipment,
        itemName: event.itemName,
        equipmentMethod: event.method,
      ),
      onData: (result) {
        if (result.isLeft()) return state;
        final refusal = result.getRightOrNull();
        if (refusal == null) return _stateWithNotice(_shownNotices[shownKey]);
        add(
          EquipmentRefusalNoticeLookedUp(
            companyId: companyId,
            itemName: event.itemName,
            refusal: refusal,
          ),
        );
        return _stateWithNotice(_noticeOf(refusal, estimateName: null));
      },
    );
  }

  Future<String?> _resolveCompanyId() async {
    final resolved = _companyId;
    if (resolved != null) return resolved;
    final result = await _companyResolver.resolve();
    return _companyId = result.getRightOrNull();
  }

  Future<void> _onRefusalNoticeLookedUp(
    EquipmentRefusalNoticeLookedUp event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    final method = event.refusal.equipmentMethod;
    if (method == null) return;
    final lookup = await _repository.getEstimateNameKeepingEquipmentRate(
      companyId: event.companyId,
      itemName: event.refusal.itemName,
      pricingMethod: method,
      rateAmount: event.refusal.refusedAmount,
    );
    final current = state.formData.refusedDefault;
    final base = _noticeOf(event.refusal, estimateName: null);
    if (current != base) return;
    emit(
      _stateWithNotice(
        lookup.fold(
          (_) => _noticeOf(
            event.refusal,
            estimateName: null,
            estimateLookupFailed: true,
          ),
          (name) => _noticeOf(event.refusal, estimateName: name),
        ),
      ),
    );
  }

  Future<void> _onRefusalNoticeSeen(
    EquipmentRefusalNoticeSeen event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    final notice = state.formData.refusedDefault;
    final companyId = _companyId;
    if (notice == null || companyId == null) return;
    if (notice.estimateLookupFailed) return;
    final itemName = state.formData.equipmentType;
    final method = state.formData.method;
    final marked = await _yourRatesRepository.markRefusalShown(
      companyId: companyId,
      category: CostItemType.equipment,
      itemName: itemName,
      equipmentMethod: method,
    );
    if (marked.isRight()) {
      _shownNotices[_shownKeyOf(itemName, method)] = notice;
    }
  }

  static String _shownKeyOf(String itemName, EquipmentPricingMethod method) =>
      '${YourRateRefusalKey.normalizeName(itemName)}|${method.toJson()}';

  RefusedDefaultNotice _noticeOf(
    RefusedYourRate refusal, {
    required String? estimateName,
    bool estimateLookupFailed = false,
  }) => RefusedDefaultNotice(
    refusedAmount: refusal.refusedAmount,
    acceptedAmount: refusal.acceptedAmount,
    estimateName: estimateName,
    estimateLookupFailed: estimateLookupFailed,
  );

  // Changes only the notice of the current state, whatever the state is, so a
  // refusal that arrives late cannot turn a confirmation or a success back
  // into plain editing.
  EquipmentCostFormState _stateWithNotice(RefusedDefaultNotice? notice) {
    final current = state;
    if (current.formData.refusedDefault == notice) return current;
    final data = current.formData.copyWith(refusedDefault: notice);
    return switch (current) {
      EquipmentCostFormInitial() ||
      EquipmentCostFormEditing() => EquipmentCostFormEditing(_validated(data)),
      EquipmentCostFormOutsizedFeeConfirm() =>
        EquipmentCostFormOutsizedFeeConfirm(data),
      EquipmentCostFormSubmitting() => EquipmentCostFormSubmitting(data),
      EquipmentCostFormSuccess(:final createdItem) => EquipmentCostFormSuccess(
        data,
        createdItem,
      ),
      EquipmentCostFormFailure(:final failure) => EquipmentCostFormFailure(
        data,
        failure,
      ),
    };
  }

  void _emit(
    Emitter<EquipmentCostFormState> emit,
    EquipmentCostFormData Function(EquipmentCostFormData) update,
  ) {
    final validated = _validated(update(state.formData));
    final next = validated.copyWith(
      hasUnsavedChanges: _differsFromOpened(validated),
    );
    emit(switch (state) {
      EquipmentCostFormFailure(:final failure) => EquipmentCostFormFailure(
        next,
        failure,
      ),
      _ => EquipmentCostFormEditing(next),
    });
  }

  bool _differsFromOpened(EquipmentCostFormData data) =>
      data.method != _formValuesAtOpening.method ||
      data.equipmentType.trim() != _formValuesAtOpening.equipmentType.trim() ||
      data.duration != _formValuesAtOpening.duration ||
      data.dailyRate != _formValuesAtOpening.dailyRate ||
      data.jobAmount != _formValuesAtOpening.jobAmount ||
      data.deliveryFee != _formValuesAtOpening.deliveryFee ||
      data.description != _formValuesAtOpening.description;

  Future<void> _onSubmitted(
    EquipmentCostSubmittedEvent event,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    // A second tap while the first submit is in flight (or has already
    // succeeded) must not insert a duplicate cost line.
    if (state is EquipmentCostFormSubmitting ||
        state is EquipmentCostFormSuccess) {
      return;
    }
    final draft = _validated(state.formData);
    if (!draft.isValid) {
      emit(EquipmentCostFormEditing(draft));
      return;
    }
    if (_isOutsizedFee(draft)) {
      emit(EquipmentCostFormOutsizedFeeConfirm(draft));
      return;
    }
    await _submit(draft, event.estimateId, emit);
  }

  bool _isOutsizedFee(EquipmentCostFormData draft) {
    final fee = draft.deliveryFee;
    if (fee == null) return false;
    final baseCost = draft.baseCost;
    return baseCost > 0 && fee > baseCost;
  }

  void _onOutsizedFeeDeclined(
    EquipmentOutsizedFeeDeclinedEvent event,
    Emitter<EquipmentCostFormState> emit,
  ) {
    final current = state;
    if (current is! EquipmentCostFormOutsizedFeeConfirm) return;
    emit(EquipmentCostFormEditing(current.data));
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
    EquipmentCostFormData draft,
    String estimateId,
    Emitter<EquipmentCostFormState> emit,
  ) async {
    emit(EquipmentCostFormSubmitting(draft));
    final result = await _repository.createCostItem(
      _buildCostItem(draft, estimateId),
    );
    final created = result.fold<CostItem?>((failure) {
      emit(EquipmentCostFormFailure(draft, failure));
      return null;
    }, (item) => item);
    if (created == null) return;
    emit(EquipmentCostFormSuccess(draft, created));
    final recalledRateId = draft.recalledRateId;
    if (recalledRateId != null && draft.method == draft.recalledRateMethod) {
      await _yourRatesRepository.recordRateUse(recalledRateId);
    }
  }

  EquipmentCostFormData _validated(EquipmentCostFormData draft) {
    final errors = <EquipmentFormField, EquipmentFieldError>{};
    final hasItemType = draft.equipmentType.trim().isNotEmpty;

    final bool hasDuration;
    final bool hasRate;
    if (draft.method == EquipmentPricingMethod.day) {
      hasDuration = _validateDuration(draft.duration, errors);
      hasRate = _validateRate(
        draft.dailyRate,
        EquipmentFormField.dailyRate,
        errors,
      );
    } else {
      hasDuration = true;
      hasRate = _validateRate(
        draft.jobAmount,
        EquipmentFormField.jobAmount,
        errors,
      );
    }
    return draft.copyWith(
      isValid: hasItemType && hasDuration && hasRate,
      fieldErrors: errors,
    );
  }

  bool _validateDuration(
    double? duration,
    Map<EquipmentFormField, EquipmentFieldError> errors,
  ) {
    if (duration == null) return false;
    if (!(duration > 0 && duration.isFinite)) {
      errors[EquipmentFormField.duration] =
          EquipmentFieldError.durationNotPositive;
      return false;
    }
    if (duration > _durationColumnMax) {
      errors[EquipmentFormField.duration] =
          EquipmentFieldError.durationTooLarge;
      return false;
    }
    if (!_isHalfDayStep(duration)) {
      errors[EquipmentFormField.duration] =
          EquipmentFieldError.durationNotHalfDay;
      return false;
    }
    return true;
  }

  bool _isHalfDayStep(double duration) {
    final doubled = duration * 2;
    return (doubled - doubled.roundToDouble()).abs() < 1e-9;
  }

  bool _validateRate(
    double? rate,
    EquipmentFormField field,
    Map<EquipmentFormField, EquipmentFieldError> errors,
  ) {
    if (rate == null) return false;
    final inRange =
        !rate.isNaN &&
        !rate.isInfinite &&
        rate >= _minRate &&
        rate <= largestMoneyAmount;
    if (!inRange) {
      errors[field] = EquipmentFieldError.rateOutOfRange;
    }
    return inRange;
  }

  EquipmentCostItem _buildCostItem(
    EquipmentCostFormData draft,
    String estimateId,
  ) {
    final now = _clock.now();
    final isDay = draft.method == EquipmentPricingMethod.day;
    final duration = draft.duration;
    final dailyRate = draft.dailyRate;
    final jobAmount = draft.jobAmount;
    final deliveryFee = draft.deliveryFee;
    return EquipmentCostItem(
      id: '',
      estimateId: estimateId,
      itemName: draft.equipmentType,
      calculation: {
        if (isDay) 'daily_rate': dailyRate ?? 0,
        if (isDay) 'duration': duration ?? 0,
        if (!isDay) 'job_amount': jobAmount ?? 0,
        'delivery_fee': ?deliveryFee,
      },
      itemTotalCost: draft.lineTotal,
      createdAt: now,
      updatedAt: now,
      // TODO: [CA-1223] no multi-currency support yet. https://ripplearc.youtrack.cloud/issue/CA-1223
      currency: 'USD',
      pricingMethod: draft.method,
      rateStatus: draft.rateStatus,
      duration: isDay ? duration : null,
      dailyRate: isDay && dailyRate != null ? Money(amount: dailyRate) : null,
      jobAmount: !isDay && jobAmount != null ? Money(amount: jobAmount) : null,
      deliveryFee: deliveryFee != null ? Money(amount: deliveryFee) : null,
      description: draft.description,
    );
  }
}
