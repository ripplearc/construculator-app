import 'package:construculator/libraries/supabase/database_constants.dart';
import 'package:equatable/equatable.dart';

/// A Your rates default the server refused, as kept on the phone.
class YourRateRefusalDto extends Equatable {
  /// The `YourRateRefusalKey` of the item: user, company, category, name and method.
  final String id;

  /// The user whose save the server refused.
  final String userId;

  /// The company the refused default belongs to.
  final String companyId;

  /// The cost item category of the refused default, for example `equipment`.
  final String category;

  /// The id of the your_rates row the server refused.
  final String refusedRowId;

  /// The item name as the user saved it.
  final String itemName;

  /// How the item is priced, or null for an item with no pricing method.
  final String? equipmentMethod;

  /// The label of the refused row, or null if it had none.
  final String? entryLabel;

  /// The amount the server refused.
  final double refusedAmount;

  /// The last amount the server accepted for the item, or null if it never
  /// accepted one.
  final double? acceptedAmount;

  /// When the "Not kept" message was shown, or null if it has not been.
  final String? shownAt;

  /// Creates a refusal as kept on the phone.
  const YourRateRefusalDto({
    required this.id,
    required this.userId,
    required this.companyId,
    required this.category,
    required this.refusedRowId,
    required this.itemName,
    required this.equipmentMethod,
    required this.entryLabel,
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
      userId: json[DatabaseConstants.userIdColumn] as String,
      companyId: json[DatabaseConstants.companyIdColumn] as String,
      category: json[DatabaseConstants.categoryColumn] as String,
      refusedRowId: json[DatabaseConstants.refusedRowIdColumn] as String,
      itemName: json[DatabaseConstants.itemNameColumn] as String,
      equipmentMethod: json[DatabaseConstants.equipmentMethodColumn] as String?,
      entryLabel: json[DatabaseConstants.entryLabelColumn] as String?,
      refusedAmount: (json[DatabaseConstants.refusedAmountColumn] as num)
          .toDouble(),
      acceptedAmount: (json[DatabaseConstants.acceptedAmountColumn] as num?)
          ?.toDouble(),
      shownAt: json[DatabaseConstants.shownAtColumn] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    companyId,
    category,
    refusedRowId,
    itemName,
    equipmentMethod,
    entryLabel,
    refusedAmount,
    acceptedAmount,
    shownAt,
  ];
}
