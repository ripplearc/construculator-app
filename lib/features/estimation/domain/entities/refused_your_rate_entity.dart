import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:equatable/equatable.dart';

/// A Your rates default the server refused: the price the user tried to keep,
/// and the last price the server accepted for the same item.
class RefusedYourRate extends Equatable {
  const RefusedYourRate({
    required this.itemName,
    required this.equipmentMethod,
    required this.refusedAmount,
    required this.acceptedAmount,
  });

  final String itemName;

  /// How the item is priced, or null for an item that has no pricing method.
  final EquipmentPricingMethod? equipmentMethod;

  /// The amount the server refused.
  final double refusedAmount;

  /// The last amount the server accepted, or null if it never accepted one.
  final double? acceptedAmount;

  @override
  List<Object?> get props => [
    itemName,
    equipmentMethod,
    refusedAmount,
    acceptedAmount,
  ];
}
