import 'package:equatable/equatable.dart';

/// Sentinel value used in copyWith methods to explicitly clear nullable fields.
///
/// Usage:
/// ```dart
/// item.copyWith(productLink: clearField())
/// ```
/// This will set productLink to null, as opposed to omitting the parameter
/// which preserves the current value.
const _ClearField _clearField = _ClearField();

/// Sentinel class for clearing nullable fields in copyWith methods.
class _ClearField {
  const _ClearField();
}

/// Helper function to create a clear field sentinel.
///
/// Returns a special sentinel value that can be passed to copyWith methods
/// to explicitly set nullable fields to null.
Object clearField() => _clearField;

/// Type of cost item stored in an estimation.
enum CostItemType {
  /// A physical or consumable item priced by unit and quantity.
  material,

  /// Labor work tracked by hours, days, or per-unit pricing.
  labor,

  /// Equipment or rented assets priced by unit and quantity.
  equipment;

  String toJson() => name;

  /// Deserializes a [CostItemType] from JSON string.
  ///
  /// Falls back to [CostItemType.material] for unknown values to ensure
  /// forward compatibility with new item types added in future versions.
  /// This allows older clients to gracefully handle unknown types by treating
  /// them as materials, which is the most common and safest default.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static CostItemType fromJson(String value) {
    return CostItemType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => CostItemType.material,
    );
  }
}

/// Units supported for material and equipment quantities.
enum Unit {
  /// Individual countable items.
  pieces,

  /// Linear length measured in meters.
  meters,

  /// Area measured in square meters.
  squareMeters,

  /// Volume measured in cubic meters.
  cubicMeters,

  /// Mass measured in kilograms.
  kilograms,

  /// Heavy mass measured in metric tons.
  tons,

  /// Volume measured in liters.
  liters,

  /// Time measured in hours.
  hours,

  /// Time measured in days.
  days,

  /// Bundled items counted as boxes.
  boxes,

  /// Bundled items counted as bags.
  bags,

  /// Rolled material counted as rolls.
  rolls,

  /// Sheet-based material counted as sheets.
  sheets;

  String toJson() => name;

  /// Deserializes a [Unit] from JSON string.
  ///
  /// Falls back to [Unit.pieces] for unknown values to ensure forward
  /// compatibility with new units added in future versions. Pieces is chosen
  /// as the default because it is the most generic unit and can represent
  /// discrete countable items without requiring specific measurements.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static Unit fromJson(String value) {
    return Unit.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Unit.pieces,
    );
  }
}

/// Labor pricing strategies supported by the estimation model.
enum LaborCalculationMethodType {
  /// Labor is priced per hour of work.
  perHour('per_hour'),

  /// Labor is priced per day of work.
  perDay('per_day'),

  /// Labor is priced per unit of completed work.
  perUnit('per_unit');

  final String value;
  const LaborCalculationMethodType(this.value);

  String toJson() => value;

  /// Deserializes a [LaborCalculationMethodType] from JSON string.
  ///
  /// Falls back to [LaborCalculationMethodType.perHour] for unknown values to
  /// ensure forward compatibility with new calculation methods added in future
  /// versions. Per hour is chosen as the default because it is the most common
  /// labor pricing strategy and provides a conservative fallback that requires
  /// explicit time tracking.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static LaborCalculationMethodType fromJson(String value) {
    return LaborCalculationMethodType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LaborCalculationMethodType.perHour,
    );
  }
}

/// Value object representing a monetary amount
class Money extends Equatable {
  final double amount;
  final String currency;

  const Money({required this.amount, this.currency = 'USD'});

  @override
  List<Object?> get props => [amount, currency];

  Money copyWith({double? amount, String? currency}) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }
}

/// Value object representing a quantity with unit
class Quantity extends Equatable {
  final double value;
  final Unit unit;

  const Quantity({required this.value, required this.unit});

  @override
  List<Object?> get props => [value, unit];

  Quantity copyWith({double? value, Unit? unit}) {
    return Quantity(value: value ?? this.value, unit: unit ?? this.unit);
  }
}

/// Value object representing labor calculation values.
///
/// Stores the computed or input values used for labor cost calculations.
/// Different fields are populated based on the [LaborCalculationMethodType]:
/// - For hourly: [laborHours] contains total hours
/// - For daily: [laborDays] contains total days
/// - For perUnit: [laborUnitValue] contains the calculated labor cost per unit,
///   and [laborUnitType] describes the unit (e.g., "per_sqm", "per_door")
///
/// Note: [laborUnitType] is a free-form String representing the specific unit
/// of work (e.g., "per_square_meter", "per_window") distinct from the
/// [LaborCalculationMethodType] enum which defines the pricing strategy.
class LaborValue extends Equatable {
  /// Total number of days for daily labor calculations.
  final double? laborDays;

  /// Total number of hours for hourly labor calculations.
  final double? laborHours;

  /// Free-form description of the work unit for per-unit calculations.
  /// Examples: "per_sqm", "per_door", "per_installation".
  /// This is distinct from [LaborCalculationMethodType] which defines
  /// the pricing strategy (hourly/daily/perUnit).
  final String? laborUnitType;

  /// Calculated labor cost per unit for per-unit calculations.
  final double? laborUnitValue;

  const LaborValue({
    this.laborDays,
    this.laborHours,
    this.laborUnitType,
    this.laborUnitValue,
  });

  @override
  List<Object?> get props => [
    laborDays,
    laborHours,
    laborUnitType,
    laborUnitValue,
  ];

  /// Creates a copy of this [LaborValue] with the given fields replaced.
  ///
  /// To explicitly clear a nullable field, pass [clearField()] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = value.copyWith(
  ///   laborDays: 5.0,           // Update to 5.0
  ///   laborHours: clearField(), // Clear to null
  /// );                          // laborUnitType unchanged
  /// ```
  LaborValue copyWith({
    Object? laborDays,
    Object? laborHours,
    Object? laborUnitType,
    Object? laborUnitValue,
  }) {
    return LaborValue(
      laborDays: laborDays == _clearField
          ? null
          : (laborDays as double?) ?? this.laborDays,
      laborHours: laborHours == _clearField
          ? null
          : (laborHours as double?) ?? this.laborHours,
      laborUnitType: laborUnitType == _clearField
          ? null
          : (laborUnitType as String?) ?? this.laborUnitType,
      laborUnitValue: laborUnitValue == _clearField
          ? null
          : (laborUnitValue as double?) ?? this.laborUnitValue,
    );
  }
}

/// Sealed class representing a cost item in an estimation
sealed class CostItem extends Equatable {
  final String id;
  final String estimateId;
  final String itemName;
  final CostItemType itemType;

  /// Breakdown of cost calculation components as key-value pairs.
  ///
  /// This map stores intermediate calculation values for transparency and auditing.
  /// Common keys include:
  /// - "unitPrice": The price per unit (for materials/equipment)
  /// - "quantity": The quantity purchased/used
  /// - "subtotal": Subtotal before adjustments
  /// - "taxRate": Applied tax rate (if applicable)
  /// - "taxAmount": Calculated tax amount
  /// - "discountRate": Applied discount rate (if applicable)
  /// - "discountAmount": Calculated discount amount
  /// - "laborRate": Rate per hour/day (for labor items)
  /// - "hours" or "days": Time worked
  /// - "markup": Markup percentage or amount
  ///
  /// The exact keys present depend on the [CostItemType] and calculation method.
  /// Consumer code should handle missing keys gracefully.
  final Map<String, double> calculation;

  final double itemTotalCost;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productLink;
  final String? description;

  const CostItem({
    required this.id,
    required this.estimateId,
    required this.itemName,
    required this.itemType,
    required this.calculation,
    required this.itemTotalCost,
    required this.createdAt,
    required this.updatedAt,
    this.productLink,
    this.description,
  });

  @override
  List<Object?> get props => [
    id,
    estimateId,
    itemName,
    itemType,
    calculation,
    itemTotalCost,
    createdAt,
    updatedAt,
    productLink,
    description,
  ];
}

/// Material cost item with unit price and quantity.
///
/// Although structurally identical to [EquipmentCostItem], this class is kept
/// separate to maintain type safety and domain semantics. Materials and equipment
/// represent distinct business concepts with different:
/// - Accounting categories and tax treatment
/// - Procurement workflows and suppliers
/// - Storage and inventory management requirements
/// - Regulatory compliance and tracking needs
///
/// This separation allows the domain model to evolve independently for each
/// concept and prevents accidental conflation of semantically different items.
class MaterialCostItem extends CostItem {
  final Money unitPrice;
  final Quantity quantity;

  const MaterialCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required this.unitPrice,
    required this.quantity,
    super.productLink,
    super.description,
  }) : super(itemType: CostItemType.material);

  @override
  List<Object?> get props => [...super.props, unitPrice, quantity];

  /// Creates a copy of this [MaterialCostItem] with the given fields replaced.
  ///
  /// To explicitly clear a nullable field, pass [clearField()] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   productLink: clearField(), // Clear to null
  /// );
  /// ```
  MaterialCostItem copyWith({
    String? id,
    String? estimateId,
    String? itemName,
    Map<String, double>? calculation,
    double? itemTotalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    Money? unitPrice,
    Quantity? quantity,
    Object? productLink,
    Object? description,
  }) {
    return MaterialCostItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      itemName: itemName ?? this.itemName,
      calculation: calculation ?? this.calculation,
      itemTotalCost: itemTotalCost ?? this.itemTotalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      productLink: productLink == _clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == _clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}

/// Labor cost item with calculation method and labor values
class LaborCostItem extends CostItem {
  final LaborCalculationMethodType laborCalcMethod;
  final LaborValue laborValue;
  final int? crewSize;

  const LaborCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required this.laborCalcMethod,
    required this.laborValue,
    this.crewSize,
    super.productLink,
    super.description,
  }) : super(itemType: CostItemType.labor);

  @override
  List<Object?> get props => [
    ...super.props,
    laborCalcMethod,
    laborValue,
    crewSize,
  ];

  /// Creates a copy of this [LaborCostItem] with the given fields replaced.
  ///
  /// To explicitly clear a nullable field, pass [clearField()] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   crewSize: clearField(),    // Clear to null
  ///   productLink: clearField(), // Clear to null
  /// );
  /// ```
  LaborCostItem copyWith({
    String? id,
    String? estimateId,
    String? itemName,
    Map<String, double>? calculation,
    double? itemTotalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    LaborCalculationMethodType? laborCalcMethod,
    LaborValue? laborValue,
    Object? crewSize,
    Object? productLink,
    Object? description,
  }) {
    return LaborCostItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      itemName: itemName ?? this.itemName,
      calculation: calculation ?? this.calculation,
      itemTotalCost: itemTotalCost ?? this.itemTotalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      laborCalcMethod: laborCalcMethod ?? this.laborCalcMethod,
      laborValue: laborValue ?? this.laborValue,
      crewSize:
          crewSize == _clearField ? null : (crewSize as int?) ?? this.crewSize,
      productLink: productLink == _clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == _clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}

/// Equipment cost item with unit price and quantity.
///
/// Although structurally identical to [MaterialCostItem], this class is kept
/// separate to maintain type safety and domain semantics. Equipment and materials
/// represent distinct business concepts with different:
/// - Depreciation schedules and asset management
/// - Rental vs. purchase considerations
/// - Maintenance and operational tracking
/// - Capital expenditure vs. operational expense classification
///
/// This separation allows the domain model to evolve independently for each
/// concept and prevents accidental conflation of semantically different items.
class EquipmentCostItem extends CostItem {
  final Money unitPrice;
  final Quantity quantity;

  const EquipmentCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required this.unitPrice,
    required this.quantity,
    super.productLink,
    super.description,
  }) : super(itemType: CostItemType.equipment);

  @override
  List<Object?> get props => [...super.props, unitPrice, quantity];

  /// Creates a copy of this [EquipmentCostItem] with the given fields replaced.
  ///
  /// To explicitly clear a nullable field, pass [clearField()] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   productLink: clearField(), // Clear to null
  /// );
  /// ```
  EquipmentCostItem copyWith({
    String? id,
    String? estimateId,
    String? itemName,
    Map<String, double>? calculation,
    double? itemTotalCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    Money? unitPrice,
    Quantity? quantity,
    Object? productLink,
    Object? description,
  }) {
    return EquipmentCostItem(
      id: id ?? this.id,
      estimateId: estimateId ?? this.estimateId,
      itemName: itemName ?? this.itemName,
      calculation: calculation ?? this.calculation,
      itemTotalCost: itemTotalCost ?? this.itemTotalCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      productLink: productLink == _clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == _clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}
