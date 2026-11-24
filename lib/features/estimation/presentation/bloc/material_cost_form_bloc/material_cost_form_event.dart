part of 'material_cost_form_bloc.dart';

/// Base sealed class for all material cost form events.
sealed class MaterialCostFormEvent {
  const MaterialCostFormEvent();
}

/// Fired when the form opens, so it can load the unit last used for each
/// material.
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

/// Fired when the form opens on a name typed on the Your recents search. The
/// name counts as how the form opened, so closing it untouched asks nothing.
class MaterialNamePrefilled extends MaterialCostFormEvent {
  const MaterialNamePrefilled(this.name);

  /// The name typed on the search.
  final String name;
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

/// Fired when a saved price is attached to the line. Its unit becomes the
/// line's unit.
// TODO: [CA-1527] fire this when a rate is put on the form from Your recents, the look-up or a sample cost file. https://ripplearc.youtrack.cloud/issue/CA-1527
class MaterialPriceAttached extends MaterialCostFormEvent {
  const MaterialPriceAttached({
    required this.rate,
    required this.rateStatus,
    required this.price,
  });

  /// The price of one [AttachedPrice.buyUnit].
  final double rate;

  /// Confidence level of [rate].
  final RateStatus rateStatus;

  /// The units the price can be counted in.
  final AttachedPrice price;
}

/// Fired when the user taps Add to estimate.
class MaterialCostFormSubmitted extends MaterialCostFormEvent {
  const MaterialCostFormSubmitted({required this.estimateId});

  /// The estimate this cost item is being added to.
  final String estimateId;
}

/// Loads a line already on the estimate into the form, so Save changes that
/// line instead of adding a new one.
///
/// Dispatched once, when the sheet for that line opens.
class MaterialCostEditOpened extends MaterialCostFormEvent {
  const MaterialCostEditOpened(this.item);

  /// The line to edit.
  final MaterialCostItem item;
}

/// Deletes the line this form edits from the estimate.
///
/// Ignored when the form adds a new line, and while a save or delete is
/// running.
class MaterialCostDeleteRequested extends MaterialCostFormEvent {
  const MaterialCostDeleteRequested();
}
