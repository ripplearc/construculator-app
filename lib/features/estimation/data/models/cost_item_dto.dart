import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';
import 'package:construculator/libraries/logging/app_logger.dart';
import 'package:equatable/equatable.dart';

/// Data Transfer Object for CostItem entity.
///
/// This DTO represents the serialized form of a cost item as it appears
/// in the database or API responses. It handles the conversion between the
/// flat database structure and the domain entity's nested object structure.
///
/// The DTO contains all possible fields for material, labor, and equipment cost items.
/// The specific fields populated depend on the item_type value.
class CostItemDto extends Equatable {
  static final _logger = AppLogger().tag('CostItemDto');

  /// Unique identifier for the cost item.
  final String id;

  /// ID of the estimate this cost item belongs to.
  final String estimateId;

  /// Name of the cost item.
  final String itemName;

  /// Type of cost item: 'material', 'labor', or 'equipment'.
  final String itemType;

  /// Calculation breakdown for the cost item.
  final Map<String, dynamic> calculation;

  /// Total calculated cost for this item.
  final double itemTotalCost;

  /// ISO 8601 timestamp when the cost item was created.
  final String createdAt;

  /// ISO 8601 timestamp when the cost item was last updated.
  final String updatedAt;

  /// Optional URL link to product information.
  final String? productLink;

  /// Optional description of the cost item.
  final String? description;

  /// Unit price for material items.
  final double? unitPrice;

  /// Quantity value for material items.
  final double? quantity;

  /// Unit of measurement for material items.
  final String? unitMeasurement;

  /// Pricing strategy for equipment items: 'day' or 'job'.
  final String? pricingMethod;

  /// Number of days for day-priced equipment items.
  final double? duration;

  /// Rate per day for day-priced equipment items.
  final double? dailyRate;

  /// Flat amount for job-priced equipment items.
  final double? jobAmount;

  /// Delivery fee for equipment items; null means unquoted.
  final double? deliveryFee;

  /// Confirmation state of [deliveryFee]: 'unset', 'estimated', or 'confirmed'.
  final String? deliveryFeeStatus;

  /// Confidence level of the equipment rate: 'sample_rate_unverified',
  /// 'own_rate_confirmed', or 'missing'.
  final String? rateStatus;

  /// Labor calculation method: 'per_hour', 'per_day', or 'per_unit'.
  final String? laborCalcMethod;

  /// Number of labor days.
  final double? laborDays;

  /// Number of labor hours.
  final double? laborHours;

  /// Type of labor unit.
  final String? laborUnitType;

  /// Value per labor unit.
  final double? laborUnitValue;

  /// Size of the crew for labor items.
  final int? crewSize;

  /// ISO 4217 currency code for this cost item's monetary values.
  final String currency;

  /// Optional brand or manufacturer name for this cost item.
  final String? brand;

  /// Creates a new [CostItemDto] instance.
  const CostItemDto({
    required this.id,
    required this.estimateId,
    required this.itemName,
    required this.itemType,
    required this.calculation,
    required this.itemTotalCost,
    required this.createdAt,
    required this.updatedAt,
    required this.currency,
    this.productLink,
    this.description,
    this.unitPrice,
    this.quantity,
    this.unitMeasurement,
    this.pricingMethod,
    this.duration,
    this.dailyRate,
    this.jobAmount,
    this.deliveryFee,
    this.deliveryFeeStatus,
    this.rateStatus,
    this.laborCalcMethod,
    this.laborDays,
    this.laborHours,
    this.laborUnitType,
    this.laborUnitValue,
    this.crewSize,
    this.brand,
  });

  /// Creates a [CostItemDto] from a JSON map.
  ///
  /// This factory method handles the conversion from the database/API JSON format
  /// to the DTO structure. It performs type conversion for numeric values and
  /// maps snake_case JSON keys to camelCase Dart properties.
  factory CostItemDto.fromJson(Map<String, dynamic> json) {
    return CostItemDto(
      id: json['id'] as String,
      estimateId: json['estimate_id'] as String,
      itemName: json['item_name'] as String,
      itemType: json['item_type'] as String,
      calculation: Map<String, dynamic>.from(json['calculation'] as Map? ?? {}),
      itemTotalCost: (json['item_total_cost'] as num).toDouble(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      productLink: json['product_link'] as String?,
      description: json['description'] as String?,
      unitPrice: json['unit_price'] != null
          ? (json['unit_price'] as num).toDouble()
          : null,
      quantity: json['quantity'] != null
          ? (json['quantity'] as num).toDouble()
          : null,
      unitMeasurement: json['unit_measurement'] as String?,
      pricingMethod: json['pricing_method'] as String?,
      duration: json['duration'] != null
          ? (json['duration'] as num).toDouble()
          : null,
      dailyRate: json['daily_rate'] != null
          ? (json['daily_rate'] as num).toDouble()
          : null,
      jobAmount: json['job_amount'] != null
          ? (json['job_amount'] as num).toDouble()
          : null,
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      deliveryFeeStatus: json['delivery_fee_status'] as String?,
      rateStatus: json['rate_status'] as String?,
      laborCalcMethod: json['labor_calc_method'] as String?,
      laborDays: json['labor_days'] != null
          ? (json['labor_days'] as num).toDouble()
          : null,
      laborHours: json['labor_hours'] != null
          ? (json['labor_hours'] as num).toDouble()
          : null,
      laborUnitType: json['labor_unit_type'] as String?,
      laborUnitValue: json['labor_unit_value'] != null
          ? (json['labor_unit_value'] as num).toDouble()
          : null,
      crewSize: json['crew_size'] as int?,
      currency: json['currency'] as String,
      brand: json['brand'] as String?,
    );
  }

  /// Converts this DTO to a JSON map.
  ///
  /// This method converts the DTO back to the database/API JSON format,
  /// mapping camelCase Dart properties to snake_case JSON keys.
  Map<String, dynamic> toJson() => {
    'id': id,
    'estimate_id': estimateId,
    'item_name': itemName,
    'item_type': itemType,
    'calculation': calculation,
    'item_total_cost': itemTotalCost,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'product_link': productLink,
    'description': description,
    'unit_price': unitPrice,
    'quantity': quantity,
    'unit_measurement': unitMeasurement,
    'pricing_method': pricingMethod,
    'duration': duration,
    'daily_rate': dailyRate,
    'job_amount': jobAmount,
    'delivery_fee': deliveryFee,
    'delivery_fee_status': deliveryFeeStatus,
    'rate_status': rateStatus,
    'labor_calc_method': laborCalcMethod,
    'labor_days': laborDays,
    'labor_hours': laborHours,
    'labor_unit_type': laborUnitType,
    'labor_unit_value': laborUnitValue,
    'crew_size': crewSize,
    'currency': currency,
    'brand': brand,
  };

  /// Converts this DTO to a domain [CostItem] entity.
  ///
  /// This method performs the transformation from the flat DTO structure
  /// to the appropriate domain entity subtype based on the item_type.
  /// It creates MaterialCostItem, LaborCostItem, or EquipmentCostItem
  /// with the relevant fields populated.
  CostItem toEntity() {
    final type = CostItemType.fromJson(itemType);
    final calculationMap = <String, double>{};
    for (final entry in calculation.entries) {
      final value = entry.value;
      if (value is num) {
        calculationMap[entry.key] = value.toDouble();
      } else {
        _logger.warning(
          'Skipping non-numeric calculation entry: ${entry.key}=$value',
        );
      }
    }

    switch (type) {
      case CostItemType.material:
        final unit = Unit.fromJson(unitMeasurement ?? 'pieces');
        return MaterialCostItem(
          id: id,
          estimateId: estimateId,
          itemName: itemName,
          calculation: calculationMap,
          itemTotalCost: itemTotalCost,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
          currency: currency,
          unitPrice: Money(amount: unitPrice ?? 0.0, currency: currency),
          quantity: Quantity(value: quantity ?? 0.0, unit: unit),
          brand: brand,
          productLink: productLink,
          description: description,
        );

      case CostItemType.labor:
        final method = LaborCalculationMethodType.fromJson(
          laborCalcMethod ?? 'per_hour',
        );
        return LaborCostItem(
          id: id,
          estimateId: estimateId,
          itemName: itemName,
          calculation: calculationMap,
          itemTotalCost: itemTotalCost,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
          currency: currency,
          laborCalcMethod: method,
          laborValue: LaborValue(
            laborDays: laborDays,
            laborHours: laborHours,
            laborUnitType: laborUnitType,
            laborUnitValue: laborUnitValue,
          ),
          crewSize: crewSize,
          brand: brand,
          productLink: productLink,
          description: description,
        );

      case CostItemType.equipment:
        final method = EquipmentPricingMethod.fromJson(pricingMethod ?? 'day');
        return EquipmentCostItem(
          id: id,
          estimateId: estimateId,
          itemName: itemName,
          calculation: calculationMap,
          itemTotalCost: itemTotalCost,
          createdAt: DateTime.parse(createdAt),
          updatedAt: DateTime.parse(updatedAt),
          currency: currency,
          pricingMethod: method,
          duration: duration,
          dailyRate: _moneyOrNull(dailyRate, currency),
          jobAmount: _moneyOrNull(jobAmount, currency),
          deliveryFee: _moneyOrNull(deliveryFee, currency),
          deliveryFeeStatus: DeliveryFeeStatus.fromJson(
            deliveryFeeStatus ?? 'unset',
          ),
          rateStatus: RateStatus.fromJson(rateStatus ?? 'missing'),
          brand: brand,
          productLink: productLink,
          description: description,
        );
    }
  }

  static Money? _moneyOrNull(double? amount, String currency) {
    if (amount == null) {
      return null;
    }
    return Money(amount: amount, currency: currency);
  }

  /// Creates a [CostItemDto] from a domain [CostItem] entity.
  ///
  /// This factory method performs the transformation from the domain entity
  /// to the flat DTO structure, extracting type-specific fields.
  factory CostItemDto.fromEntity(CostItem item) {
    return CostItemDto(
      id: item.id,
      estimateId: item.estimateId,
      itemName: item.itemName,
      itemType: item.itemType.toJson(),
      calculation: item.calculation,
      itemTotalCost: item.itemTotalCost,
      createdAt: item.createdAt.toIso8601String(),
      updatedAt: item.updatedAt.toIso8601String(),
      currency: item.currency,
      brand: item.brand,
      productLink: item.productLink,
      description: item.description,
      unitPrice: switch (item) {
        MaterialCostItem() => item.unitPrice.amount,
        EquipmentCostItem() || LaborCostItem() => null,
      },
      quantity: switch (item) {
        MaterialCostItem() => item.quantity.value,
        EquipmentCostItem() || LaborCostItem() => null,
      },
      unitMeasurement: switch (item) {
        MaterialCostItem() => item.quantity.unit.toJson(),
        EquipmentCostItem() || LaborCostItem() => null,
      },
      pricingMethod: switch (item) {
        EquipmentCostItem() => item.pricingMethod.toJson(),
        MaterialCostItem() || LaborCostItem() => null,
      },
      duration: switch (item) {
        EquipmentCostItem() => item.duration,
        MaterialCostItem() || LaborCostItem() => null,
      },
      dailyRate: switch (item) {
        EquipmentCostItem() => item.dailyRate?.amount,
        MaterialCostItem() || LaborCostItem() => null,
      },
      jobAmount: switch (item) {
        EquipmentCostItem() => item.jobAmount?.amount,
        MaterialCostItem() || LaborCostItem() => null,
      },
      deliveryFee: switch (item) {
        EquipmentCostItem() => item.deliveryFee?.amount,
        MaterialCostItem() || LaborCostItem() => null,
      },
      deliveryFeeStatus: switch (item) {
        EquipmentCostItem() => item.deliveryFeeStatus.toJson(),
        MaterialCostItem() || LaborCostItem() => null,
      },
      rateStatus: switch (item) {
        EquipmentCostItem() => item.rateStatus.toJson(),
        MaterialCostItem() || LaborCostItem() => null,
      },
      laborCalcMethod: switch (item) {
        LaborCostItem() => item.laborCalcMethod.toJson(),
        MaterialCostItem() || EquipmentCostItem() => null,
      },
      laborDays: switch (item) {
        LaborCostItem() => item.laborValue.laborDays,
        MaterialCostItem() || EquipmentCostItem() => null,
      },
      laborHours: switch (item) {
        LaborCostItem() => item.laborValue.laborHours,
        MaterialCostItem() || EquipmentCostItem() => null,
      },
      laborUnitType: switch (item) {
        LaborCostItem() => item.laborValue.laborUnitType,
        MaterialCostItem() || EquipmentCostItem() => null,
      },
      laborUnitValue: switch (item) {
        LaborCostItem() => item.laborValue.laborUnitValue,
        MaterialCostItem() || EquipmentCostItem() => null,
      },
      crewSize: switch (item) {
        LaborCostItem() => item.crewSize,
        MaterialCostItem() || EquipmentCostItem() => null,
      },
    );
  }

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
    unitPrice,
    quantity,
    unitMeasurement,
    pricingMethod,
    duration,
    dailyRate,
    jobAmount,
    deliveryFee,
    deliveryFeeStatus,
    rateStatus,
    laborCalcMethod,
    laborDays,
    laborHours,
    laborUnitType,
    laborUnitValue,
    crewSize,
    currency,
    brand,
  ];
}
