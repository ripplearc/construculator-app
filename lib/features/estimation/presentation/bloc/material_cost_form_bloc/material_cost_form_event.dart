part of 'material_cost_form_bloc.dart';

/// Base sealed class for all material cost form events.
sealed class MaterialCostFormEvent {
  const MaterialCostFormEvent();
}

/// Fired when the form opens, so it can select the unit this account used last.
class MaterialCostFormStarted extends MaterialCostFormEvent {
  const MaterialCostFormStarted();
}

/// Fired when the form opens on a rate picked from Your rates. The name, rate
/// and unit arrive filled in and count as how the form opened, so closing it
/// untouched asks nothing.
class MaterialSavedRateRecalled extends MaterialCostFormEvent {
  const MaterialSavedRateRecalled(this.entry);

  /// The saved rate that was picked.
  final YourRateEntry entry;
}

/// Fired when a rate is picked on the Look up a rate sheet. Fills the rate and
/// its unit, and the name only while it is empty; unlike
/// [MaterialSavedRateRecalled] this is an edit, so closing the form asks.
class MaterialRateLookedUp extends MaterialCostFormEvent {
  const MaterialRateLookedUp(this.entry);

  /// The saved rate that was picked.
  final YourRateEntry entry;
}

/// Fired when the user changes the material name.
class MaterialCostItemTypeChanged extends MaterialCostFormEvent {
  const MaterialCostItemTypeChanged(this.value);

  /// The new material name entered by the user.
  final String value;
}

/// Fired when the user edits the quantity.
class MaterialQuantityUpdated extends MaterialCostFormEvent {
  const MaterialQuantityUpdated(this.value);

  /// The raw quantity text entered by the user.
  final String value;
}

/// Fired when the user picks a unit from the unit list.
class MaterialUnitSelected extends MaterialCostFormEvent {
  const MaterialUnitSelected(this.unit);

  /// The unit picked by the user.
  final Unit unit;
}

/// Fired when the user edits the rate.
class MaterialRateUpdated extends MaterialCostFormEvent {
  const MaterialRateUpdated(this.value);

  /// The raw rate text entered by the user.
  final String value;
}

/// Fired when the user taps Add to estimate.
class MaterialCostFormSubmitted extends MaterialCostFormEvent {
  const MaterialCostFormSubmitted({required this.estimateId});

  /// The estimate this cost item is being added to.
  final String estimateId;
}
