part of 'equipment_cost_form_bloc.dart';

/// Base sealed class for all equipment cost form events.
sealed class EquipmentCostFormEvent {
  const EquipmentCostFormEvent();
}

/// Fired when the user changes the equipment type selection.
class EquipmentCostItemTypeChanged extends EquipmentCostFormEvent {
  const EquipmentCostItemTypeChanged(this.value);
  final String value;
}

/// Fired when the user switches pricing method between Day and Job. Field
/// values already entered are preserved across the switch.
class EquipmentMethodSwitchedEvent extends EquipmentCostFormEvent {
  const EquipmentMethodSwitchedEvent(this.method);
  final EquipmentPricingMethod method;
}

/// Fired when the user edits the duration field under Day pricing.
class EquipmentDurationUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentDurationUpdatedEvent(this.value);
  final String value;
}

/// Fired when the user edits the rate field: the daily rate under Day
/// pricing, or the flat job amount under Job pricing, depending on the
/// currently active [EquipmentPricingMethod].
class EquipmentRateUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentRateUpdatedEvent(this.value);
  final String value;
}

/// Fired when the user edits the delivery fee field.
class EquipmentDeliveryFeeUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentDeliveryFeeUpdatedEvent(this.value);
  final String value;
}

/// Fired when the user confirms the currently entered delivery fee quote.
class EquipmentDeliveryFeeConfirmedEvent extends EquipmentCostFormEvent {
  const EquipmentDeliveryFeeConfirmedEvent();
}

/// Fired when the user edits the item's note. The field is placed inside the
/// expanded delivery-fee editor, but the value it carries is the whole cost
/// item's [EquipmentCostItem.description], the same item-level field Material
/// and Labour items use — not something scoped to the delivery fee.
class EquipmentDescriptionUpdatedEvent extends EquipmentCostFormEvent {
  const EquipmentDescriptionUpdatedEvent(this.value);
  final String value;
}

/// Fired when the user recalls a saved rate from Your Rates (the
/// Look-up-a-rate sheet or Your recents) — CUJ 6 Sub-flows B and C. Unlike
/// [EquipmentRateUpdatedEvent], which always lands as
/// [RateStatus.ownRateUnconfirmed], a recalled rate is already verified: it
/// was confirmed the moment it was saved to Your Rates, so recalling it is
/// not the same as a fresh, unconfirmed keystroke.
class EquipmentSavedRateRecalledEvent extends EquipmentCostFormEvent {
  const EquipmentSavedRateRecalledEvent({
    required this.equipmentType,
    required this.method,
    required this.rate,
  });

  /// The recalled entry's item name, applied to the equipment name field.
  final String equipmentType;

  /// Which pricing method the recalled entry was saved under. The rate lands
  /// in [EquipmentCostFormWithData.dailyRate] or `.jobAmount` accordingly.
  final EquipmentPricingMethod method;

  /// The recalled rate amount.
  final double rate;
}

/// Fired when the user submits the equipment cost form.
class EquipmentCostSubmittedEvent extends EquipmentCostFormEvent {
  const EquipmentCostSubmittedEvent({required this.estimateId});
  final String estimateId;
}

/// Fired when the user accepts an outsized fee, resuming submission from
/// [EquipmentCostFormOutsizedFeeConfirm].
class EquipmentOutsizedFeeAcceptedEvent extends EquipmentCostFormEvent {
  const EquipmentOutsizedFeeAcceptedEvent({required this.estimateId});
  final String estimateId;
}
