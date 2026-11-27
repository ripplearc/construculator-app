import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:equatable/equatable.dart';

/// The fields of a cost form that was left open when the phone closed the app,
/// kept so the line can be finished later.
///
/// One record serves Material, Labor and Equipment. A field the form of
/// [category] does not have stays null.
class UnfinishedCostLine extends Equatable {
  const UnfinishedCostLine({
    required this.category,
    required this.estimateId,
    this.costItemId,
    this.itemName = '',
    this.quantity,
    this.unit,
    this.rate,
    this.wastePercent,
    this.note,
    required this.updatedAt,
  });

  /// The cost form the line was typed in.
  final CostItemType category;

  /// The estimate the line was going to be added to.
  final String estimateId;

  /// The saved line being changed, or null for a new line.
  final String? costItemId;

  /// The item name typed so far.
  final String itemName;

  /// The quantity typed so far, or null when none is readable.
  final double? quantity;

  /// The unit picked so far, or null when none is picked.
  final Unit? unit;

  /// The rate typed so far, or null when none is readable.
  final double? rate;

  /// The waste typed so far, in percent, or null when none is typed.
  final double? wastePercent;

  /// The note typed so far, or null when none is typed.
  final String? note;

  /// When the line was last changed.
  final DateTime updatedAt;

  /// Whether this is a change to a line already in the estimate, rather than
  /// a line not added yet.
  bool get isChangeToSavedLine => costItemId != null;

  /// This record as JSON, with the change time in UTC.
  Map<String, dynamic> toJson() => {
    'category': category.name,
    'estimateId': estimateId,
    'costItemId': costItemId,
    'itemName': itemName,
    'quantity': quantity,
    'unit': unit?.name,
    'rate': rate,
    'wastePercent': wastePercent,
    'note': note,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    category,
    estimateId,
    costItemId,
    itemName,
    quantity,
    unit,
    rate,
    wastePercent,
    note,
    updatedAt,
  ];
}
