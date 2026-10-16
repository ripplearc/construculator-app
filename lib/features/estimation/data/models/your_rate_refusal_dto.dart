import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/features/estimation/domain/entities/refused_your_rate_entity.dart';
import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// A Your rates default the server refused, as kept on the phone.
class YourRateRefusalDto extends Equatable {
  final String id;
  final String itemName;
  final String? equipmentMethod;

  /// The amount the server refused.
  final double refusedAmount;

  /// The last amount the server accepted for the item, or null if it never
  /// accepted one.
  final double? acceptedAmount;

  /// When the "Not kept" message was shown, or null if it has not been.
  final String? shownAt;

  const YourRateRefusalDto({
    required this.id,
    required this.itemName,
    required this.equipmentMethod,
    required this.refusedAmount,
    required this.acceptedAmount,
    required this.shownAt,
  });

  /// Reads a row of the `your_rate_refusals` table.
  ///
  /// Throws a [TypeError] if a required column is missing or mistyped.
  factory YourRateRefusalDto.fromJson(Map<String, dynamic> json) {
    return YourRateRefusalDto(
      id: json[DatabaseConstants.idColumn] as String,
      itemName: json[DatabaseConstants.itemNameColumn] as String,
      equipmentMethod: json[DatabaseConstants.equipmentMethodColumn] as String?,
      refusedAmount: (json[DatabaseConstants.refusedAmountColumn] as num)
          .toDouble(),
      acceptedAmount: (json[DatabaseConstants.acceptedAmountColumn] as num?)
          ?.toDouble(),
      shownAt: json[DatabaseConstants.shownAtColumn] as String?,
    );
  }

  RefusedYourRate toEntity() {
    final method = equipmentMethod;
    return RefusedYourRate(
      itemName: itemName,
      equipmentMethod: method == null
          ? null
          : EquipmentPricingMethod.fromJson(method),
      refusedAmount: refusedAmount,
      acceptedAmount: acceptedAmount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    itemName,
    equipmentMethod,
    refusedAmount,
    acceptedAmount,
    shownAt,
  ];
}
