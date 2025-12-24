import 'package:construculator/features/estimation/domain/entities/enums.dart';
import 'package:equatable/equatable.dart';

/// Represents a markup value with its type and amount.
///
/// A markup value consists of a type (percentage or fixed amount) and the
/// actual value to be applied. This allows for flexible markup calculations
/// where different cost components can have different markup strategies.
class MarkupValue extends Equatable {
  /// The type of markup value (percentage or fixed amount).
  final MarkupValueType type;

  /// The numeric value of the markup.
  ///
  /// For percentage type: represents the percentage (e.g., 15.0 for 15%)
  /// For amount type: represents the fixed dollar amount
  final double value;

  /// Creates a new markup value with the specified type and value.
  const MarkupValue({required this.type, required this.value});

  @override
  List<Object?> get props => [type, value];
}

/// Configuration for markup calculations in cost estimates.
///
/// This class defines how markups are applied to different cost components
/// in a construction project estimate. It supports two main strategies:
///
/// 1. **Overall markup**: A single markup applied to the entire project
/// 2. **Granular markup**: Separate markups for materials, labor, and equipment
///
/// The configuration allows for flexible markup strategies where different
/// cost components can have different markup types (percentage vs fixed amount)
/// and values, enabling precise control over profit margins and overhead costs.
///
/// Details can be found in the detailed design document:
/// https://docs.google.com/document/d/1MHn-LanxVJ96-HSe47C9Km0evtkPcyQDw9eDzFD60AA/edit?tab=t.m4ek8adycklb#bookmark=id.mbxhw044p7n3
class MarkupConfiguration extends Equatable {
  /// The type of overall markup strategy (overall or granular).
  final MarkupType overallType;

  /// The overall markup value to be applied.
  final MarkupValue overallValue;

  /// The type of markup for material costs (nullable for overall strategy).
  final MarkupType? materialValueType;

  /// The markup value for material costs (nullable for overall strategy).
  final MarkupValue? materialValue;

  /// The type of markup for labor costs (nullable for overall strategy).
  final MarkupType? laborValueType;

  /// The markup value for labor costs (nullable for overall strategy).
  final MarkupValue? laborValue;

  /// The type of markup for equipment costs (nullable for overall strategy).
  final MarkupType? equipmentValueType;

  /// The markup value for equipment costs (nullable for overall strategy).
  final MarkupValue? equipmentValue;

  /// Creates a new markup configuration.
  ///
  /// [overallType] and [overallValue] are required and define the primary
  /// markup strategy and value.
  ///
  /// The granular markup fields ([materialValueType], [materialValue],
  /// [laborValueType], [laborValue], [equipmentValueType], [equipmentValue])
  /// are optional and only used when [overallType] is [MarkupType.granular].
  const MarkupConfiguration({
    required this.overallType,
    required this.overallValue,
    this.materialValueType,
    this.materialValue,
    this.laborValueType,
    this.laborValue,
    this.equipmentValueType,
    this.equipmentValue,
  });

  @override
  List<Object?> get props => [
    overallType,
    overallValue,
    materialValueType,
    materialValue,
    laborValueType,
    laborValue,
    equipmentValueType,
    equipmentValue,
  ];
}
