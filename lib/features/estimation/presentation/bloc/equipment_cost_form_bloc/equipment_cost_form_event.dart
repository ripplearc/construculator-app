part of 'equipment_cost_form_bloc.dart';

/// Base sealed class for all equipment cost form events.
sealed class EquipmentCostFormEvent {
  const EquipmentCostFormEvent();
}

/// Fired when the user changes the equipment type selection.
class EquipmentCostItemTypeChanged extends EquipmentCostFormEvent {
  const EquipmentCostItemTypeChanged(this.value);

  /// The new equipment type/name value.
  final String value;
}

/// Fired when the user switches pricing method between Day and Job. Field
/// values already entered are preserved across the switch.
class EquipmentMethodSwitchedEvent extends EquipmentCostFormEvent {
  const EquipmentMethodSwitchedEvent(this.method);

  /// The pricing method the user switched to.
  final EquipmentPricingMethod method;
}

/// Fired when the user edits the duration field under Day pricing.
class EquipmentDurationUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentDurationUpdatedEvent(this.value);

  /// The raw duration text entered by the user.
  final String value;
}

/// Fired when the user edits the rate field: the daily rate under Day
/// pricing, or the flat job amount under Job pricing, depending on the
/// currently active [EquipmentPricingMethod].
class EquipmentRateUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentRateUpdatedEvent(this.value);

  /// The raw rate/amount text entered by the user.
  final String value;
}

/// Fired when the user edits the delivery fee field. A typed amount
/// (including 0) is final immediately; there is no separate confirm step.
class EquipmentDeliveryFeeUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentDeliveryFeeUpdatedEvent(this.value);

  /// The raw delivery fee text entered by the user.
  final String value;
}

/// Fired when the user submits the equipment cost form.
class EquipmentCostSubmittedEvent extends EquipmentCostFormEvent {
  const EquipmentCostSubmittedEvent({required this.estimateId});

  /// The estimate this cost item is being added to.
  final String estimateId;
}

/// Fired when the user accepts an outsized fee, resuming submission from
/// [EquipmentCostFormOutsizedFeeConfirm].
class EquipmentOutsizedFeeAcceptedEvent extends EquipmentCostFormEvent {
  const EquipmentOutsizedFeeAcceptedEvent({required this.estimateId});

  /// The estimate this cost item is being added to.
  final String estimateId;
}

/// Fired when the user chooses "Go back" on the outsized-fee dialog, returning
/// from [EquipmentCostFormOutsizedFeeConfirm] to editing.
class EquipmentOutsizedFeeDeclinedEvent extends EquipmentCostFormEvent {
  const EquipmentOutsizedFeeDeclinedEvent();
}
