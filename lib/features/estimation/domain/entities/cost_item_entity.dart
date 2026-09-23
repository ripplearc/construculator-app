import 'package:equatable/equatable.dart';

// Sentinel class for clearing nullable fields in copyWith methods.
class _ClearField {
  const _ClearField();
}

/// Sentinel value to explicitly clear a nullable field in [copyWith].
///
/// Pass this constant to set a nullable field to null instead of omitting
/// the parameter (which preserves the current value):
/// ```dart
/// item.copyWith(productLink: clearField) // sets productLink to null
/// ```
const Object clearField = _ClearField();

/// Type of cost item stored in an estimation.
enum CostItemType {
  /// A physical or consumable item priced by unit and quantity.
  material,

  /// Labor work tracked by hours, days, or per-unit pricing.
  labor,

  /// Equipment or rented assets priced by unit and quantity.
  equipment;

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

  /// Serializes this [CostItemType] to its JSON string representation.
  String toJson() => name;
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

  /// Serializes this [Unit] to its JSON string representation.
  String toJson() => name;
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
  /// Uses exact, case-sensitive matching against the snake_case [value]
  /// property (e.g., `"per_hour"`). This is intentional: the backend contract
  /// guarantees lowercase snake_case values for labor methods, unlike
  /// [CostItemType] and [Unit] which match against the Dart enum name and
  /// accept mixed-case input.
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

/// Pricing strategy for an [EquipmentCostItem]: by the day or by the job.
enum EquipmentPricingMethod {
  /// Priced using [EquipmentCostItem.duration] and [EquipmentCostItem.dailyRate].
  day,

  /// Priced as a single flat [EquipmentCostItem.jobAmount] for the whole job.
  job;

  /// Deserializes an [EquipmentPricingMethod] from JSON string.
  ///
  /// Falls back to [EquipmentPricingMethod.day] for unknown values to ensure
  /// forward compatibility with new pricing methods added in future versions.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static EquipmentPricingMethod fromJson(String value) {
    return EquipmentPricingMethod.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => EquipmentPricingMethod.day,
    );
  }

  /// Serializes this [EquipmentPricingMethod] to its JSON string representation.
  String toJson() => name;
}

/// Confirmation state of a quoted delivery fee.
///
/// Distinguishes "not yet quoted" from "confirmed zero" so the UI can show a
/// dash instead of a $0 amount until a real quote exists.
enum DeliveryFeeStatus {
  /// No delivery fee has been quoted yet.
  unset,

  /// Delivery fee is a system estimate, not yet confirmed.
  estimated,

  /// Delivery fee has been confirmed.
  confirmed;

  /// Deserializes a [DeliveryFeeStatus] from JSON string.
  ///
  /// Falls back to [DeliveryFeeStatus.unset] for unknown values to ensure
  /// forward compatibility with new statuses added in future versions.
  /// Unset is the safest default because it never implies a fee was quoted.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static DeliveryFeeStatus fromJson(String value) {
    return DeliveryFeeStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => DeliveryFeeStatus.unset,
    );
  }

  /// Serializes this [DeliveryFeeStatus] to its JSON string representation.
  String toJson() => name;
}

/// Confidence level of a rate value used in a cost item's calculation.
///
/// This is intentionally generic and not equipment-specific: it is introduced
/// for [EquipmentCostItem.rateStatus] but is designed to be adopted by
/// Material and Labor cost items in future tickets, so all cost item types
/// can express the same three-way rate confidence.
enum RateStatus {
  /// Rate comes from a generic sample/reference rate, not yet verified by the user.
  sampleRateUnverified,

  /// Rate has been confirmed as the user's own known rate.
  ownRateConfirmed,

  /// No rate value is available.
  missing;

  /// Deserializes a [RateStatus] from JSON string.
  ///
  /// Falls back to [RateStatus.missing] for unknown values to ensure forward
  /// compatibility with new statuses added in future versions. Missing is the
  /// safest default because it never implies an unverified or confirmed rate
  /// exists when the value is actually unrecognized.
  ///
  /// Note: This fallback behavior means validation errors are silent.
  /// Consider logging unknown values if strict validation is required.
  static RateStatus fromJson(String value) {
    return RateStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RateStatus.missing,
    );
  }

  /// Serializes this [RateStatus] to its JSON string representation.
  String toJson() => name;
}

/// Value object representing a monetary amount
class Money extends Equatable {
  /// The monetary amount in the given [currency].
  final double amount;

  /// ISO 4217 currency code; defaults to `'USD'`.
  final String currency;

  const Money({required this.amount, this.currency = 'USD'});

  @override
  List<Object?> get props => [amount, currency];

  /// Creates a copy of this [Money] with the given fields replaced.
  Money copyWith({double? amount, String? currency}) {
    return Money(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
    );
  }
}

/// Value object representing a quantity with unit
class Quantity extends Equatable {
  /// The numeric quantity of units.
  final double value;

  /// The unit of measurement for this quantity.
  final Unit unit;

  const Quantity({required this.value, required this.unit});

  @override
  List<Object?> get props => [value, unit];

  /// Creates a copy of this [Quantity] with the given fields replaced.
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
  /// To explicitly clear a nullable field, pass [clearField] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = value.copyWith(
  ///   laborDays: 5.0,          // Update to 5.0
  ///   laborHours: clearField,  // Clear to null
  /// );                         // laborUnitType unchanged
  /// ```
  LaborValue copyWith({
    Object? laborDays,
    Object? laborHours,
    Object? laborUnitType,
    Object? laborUnitValue,
  }) {
    return LaborValue(
      laborDays: laborDays == clearField
          ? null
          : (laborDays as double?) ?? this.laborDays,
      laborHours: laborHours == clearField
          ? null
          : (laborHours as double?) ?? this.laborHours,
      laborUnitType: laborUnitType == clearField
          ? null
          : (laborUnitType as String?) ?? this.laborUnitType,
      laborUnitValue: laborUnitValue == clearField
          ? null
          : (laborUnitValue as double?) ?? this.laborUnitValue,
    );
  }
}

/// Sealed class representing a cost item in an estimation
sealed class CostItem extends Equatable {
  /// Unique identifier for this cost item.
  final String id;

  /// The estimation this cost item belongs to.
  final String estimateId;

  /// Display name of this cost item.
  final String itemName;

  /// The type category of this cost item.
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

  /// The total computed cost for this item in [currency].
  final double itemTotalCost;

  /// Timestamp when this cost item was created.
  final DateTime createdAt;

  /// Timestamp when this cost item was last updated.
  final DateTime updatedAt;

  /// ISO 4217 currency code for this cost item's monetary values.
  final String currency;

  /// Optional brand or manufacturer name for this cost item.
  final String? brand;

  /// Optional URL linking to the product or resource for this item.
  final String? productLink;

  /// Optional freeform notes or description for this item.
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
    required this.currency,
    this.brand,
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
    currency,
    brand,
    productLink,
    description,
  ];
}

/// Material cost item with unit price and quantity.
///
/// Kept as a separate class from [EquipmentCostItem] to maintain type safety
/// and domain semantics. Materials and equipment represent distinct business
/// concepts with different:
/// - Accounting categories and tax treatment
/// - Procurement workflows and suppliers
/// - Storage and inventory management requirements
/// - Regulatory compliance and tracking needs
///
/// This separation allows the domain model to evolve independently for each
/// concept and prevents accidental conflation of semantically different items.
class MaterialCostItem extends CostItem {
  /// Price per single unit of this material.
  final Money unitPrice;

  /// Total quantity of this material with its unit of measurement.
  final Quantity quantity;

  const MaterialCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required super.currency,
    required this.unitPrice,
    required this.quantity,
    super.brand,
    super.productLink,
    super.description,
  }) : super(itemType: CostItemType.material);

  @override
  List<Object?> get props => [...super.props, unitPrice, quantity];

  /// Creates a copy of this [MaterialCostItem] with the given fields replaced.
  ///
  /// To explicitly clear a nullable field, pass [clearField] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   productLink: clearField, // Clear to null
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
    String? currency,
    Money? unitPrice,
    Quantity? quantity,
    Object? brand,
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
      currency: currency ?? this.currency,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      brand: brand == clearField ? null : (brand as String?) ?? this.brand,
      productLink: productLink == clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}

/// Labor cost item with calculation method and labor values
class LaborCostItem extends CostItem {
  /// Pricing strategy used to calculate this labor cost (hourly, daily, or per-unit).
  final LaborCalculationMethodType laborCalcMethod;

  /// Computed or input values backing the calculation; populated fields depend
  /// on [laborCalcMethod]. See [LaborValue] for details.
  final LaborValue laborValue;

  /// Optional number of workers assigned to this labor item.
  final int? crewSize;

  const LaborCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required super.currency,
    required this.laborCalcMethod,
    required this.laborValue,
    this.crewSize,
    super.brand,
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
  /// To explicitly clear a nullable field, pass [clearField] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   crewSize: clearField,   // Clear to null
  ///   productLink: clearField, // Clear to null
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
    String? currency,
    LaborCalculationMethodType? laborCalcMethod,
    LaborValue? laborValue,
    Object? crewSize,
    Object? brand,
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
      currency: currency ?? this.currency,
      laborCalcMethod: laborCalcMethod ?? this.laborCalcMethod,
      laborValue: laborValue ?? this.laborValue,
      crewSize:
          crewSize == clearField ? null : (crewSize as int?) ?? this.crewSize,
      brand: brand == clearField ? null : (brand as String?) ?? this.brand,
      productLink: productLink == clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}

/// Equipment cost item priced by the day or by the job.
///
/// Unlike [MaterialCostItem], equipment has no unit of measurement: it is
/// either priced for a [duration] of days at a [dailyRate], or as a single
/// flat [jobAmount] for the whole job. [pricingMethod] determines which pair
/// of fields is meaningful and is fixed for the lifetime of the item — see
/// [pricingMethod] for why.
///
/// Kept as a separate class from [MaterialCostItem] to maintain type safety
/// and domain semantics. Equipment and materials represent distinct business
/// concepts with different:
/// - Depreciation schedules and asset management
/// - Rental vs. purchase considerations
/// - Maintenance and operational tracking
/// - Capital expenditure vs. operational expense classification
///
/// This separation allows the domain model to evolve independently for each
/// concept and prevents accidental conflation of semantically different items.
class EquipmentCostItem extends CostItem {
  /// Pricing strategy for this equipment line: by the day or by the job.
  ///
  /// Deliberately not a [copyWith] parameter: once a line is constructed
  /// (and saved), its pricing method cannot be changed in place. Switching
  /// between day and job pricing means building a fresh [EquipmentCostItem]
  /// rather than mutating an existing one, since the two methods populate
  /// different fields ([duration]/[dailyRate] vs [jobAmount]).
  final EquipmentPricingMethod pricingMethod;

  /// Number of days this equipment was used, in days.
  ///
  /// Only set when [pricingMethod] is [EquipmentPricingMethod.day].
  final double? duration;

  /// Rate charged per day of use.
  ///
  /// Only meaningful when [pricingMethod] is [EquipmentPricingMethod.day].
  final Money? dailyRate;

  /// Flat amount charged for the whole job.
  ///
  /// Only meaningful when [pricingMethod] is [EquipmentPricingMethod.job].
  final Money? jobAmount;

  /// Delivery fee for this equipment line.
  ///
  /// `null` means the fee has not been quoted, shown as a dash in the UI.
  /// A [Money] with a zero amount means delivery has been confirmed free of
  /// charge, which is distinct from not having a quote at all.
  final Money? deliveryFee;

  /// Confirmation state of [deliveryFee].
  final DeliveryFeeStatus deliveryFeeStatus;

  /// Confidence level of the rate used for this line ([dailyRate] or [jobAmount]).
  final RateStatus rateStatus;

  const EquipmentCostItem({
    required super.id,
    required super.estimateId,
    required super.itemName,
    required super.calculation,
    required super.itemTotalCost,
    required super.createdAt,
    required super.updatedAt,
    required super.currency,
    required this.pricingMethod,
    required this.deliveryFeeStatus,
    required this.rateStatus,
    this.duration,
    this.dailyRate,
    this.jobAmount,
    this.deliveryFee,
    super.brand,
    super.productLink,
    super.description,
  }) : super(itemType: CostItemType.equipment);

  @override
  List<Object?> get props => [
    ...super.props,
    pricingMethod,
    duration,
    dailyRate,
    jobAmount,
    deliveryFee,
    deliveryFeeStatus,
    rateStatus,
  ];

  /// Creates a copy of this [EquipmentCostItem] with the given fields replaced.
  ///
  /// [pricingMethod] cannot be changed via this method — see its doc comment.
  /// To explicitly clear a nullable field, pass [clearField] as the value.
  /// Omitting a parameter preserves the current value.
  ///
  /// Example:
  /// ```dart
  /// final updated = item.copyWith(
  ///   itemName: 'New Name',
  ///   jobAmount: clearField, // Clear to null
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
    String? currency,
    Object? duration,
    Object? dailyRate,
    Object? jobAmount,
    Object? deliveryFee,
    DeliveryFeeStatus? deliveryFeeStatus,
    RateStatus? rateStatus,
    Object? brand,
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
      currency: currency ?? this.currency,
      pricingMethod: pricingMethod,
      duration: duration == clearField
          ? null
          : (duration as double?) ?? this.duration,
      dailyRate: dailyRate == clearField
          ? null
          : (dailyRate as Money?) ?? this.dailyRate,
      jobAmount: jobAmount == clearField
          ? null
          : (jobAmount as Money?) ?? this.jobAmount,
      deliveryFee: deliveryFee == clearField
          ? null
          : (deliveryFee as Money?) ?? this.deliveryFee,
      deliveryFeeStatus: deliveryFeeStatus ?? this.deliveryFeeStatus,
      rateStatus: rateStatus ?? this.rateStatus,
      brand: brand == clearField ? null : (brand as String?) ?? this.brand,
      productLink: productLink == clearField
          ? null
          : (productLink as String?) ?? this.productLink,
      description: description == clearField
          ? null
          : (description as String?) ?? this.description,
    );
  }
}
