/// Factory for creating test data for cost items.
class CostItemTestDataMapFactory {
  static Map<String, dynamic> createMaterialItemData({
    String? id,
    String? estimateId,
    String? itemName,
    String? description,
    double? unitPrice,
    String? unit,
    double? quantity,
    String? productLink,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? calculation,
    double? itemTotalCost,
    String? currency,
    double? wastePercent,
    String? rateStatus,
    String? quantityProvenance,
    String? calculatorFormula,
  }) {
    return {
      'id': id ?? 'item-material-1',
      'estimate_id': estimateId ?? 'estimate-123',
      'item_name': itemName ?? 'Test Material',
      'description': description ?? 'Test description',
      'item_type': 'material',
      'unit_price': unitPrice ?? 100.0,
      'unit_measurement': unit ?? 'pieces',
      'quantity': quantity ?? 5.0,
      'pricing_method': null,
      'duration': null,
      'daily_rate': null,
      'job_amount': null,
      'delivery_fee': null,
      'rate_status': rateStatus ?? 'missing',
      'product_link': productLink,
      'labor_calc_method': null,
      'labor_days': null,
      'labor_hours': null,
      'labor_unit_type': null,
      'labor_unit_value': null,
      'crew_size': null,
      'calculation': calculation ?? {'unit_price': 100.0, 'quantity': 5.0},
      'item_total_cost': itemTotalCost ?? 500.0,
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
      'currency': currency ?? 'USD',
      'waste_percent': wastePercent,
      'quantity_provenance': quantityProvenance ?? 'manual',
      'calculator_formula': calculatorFormula,
    };
  }

  static Map<String, dynamic> createLaborItemData({
    String? id,
    String? estimateId,
    String? itemName,
    String? description,
    String? laborCalcMethod,
    double? laborDays,
    double? laborHours,
    String? laborUnitType,
    double? laborUnitValue,
    int? crewSize,
    String? productLink,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? calculation,
    double? itemTotalCost,
    String? currency,
  }) {
    return {
      'id': id ?? 'item-labor-1',
      'estimate_id': estimateId ?? 'estimate-123',
      'item_name': itemName ?? 'Test Labor',
      'description': description ?? 'Test description',
      'item_type': 'labor',
      'unit_price': null,
      'unit_measurement': null,
      'quantity': null,
      'pricing_method': null,
      'duration': null,
      'daily_rate': null,
      'job_amount': null,
      'delivery_fee': null,
      'rate_status': null,
      'product_link': productLink,
      'labor_calc_method': laborCalcMethod ?? 'per_hour',
      'labor_days': laborDays,
      'labor_hours': laborHours ?? 10.0,
      'labor_unit_type': laborUnitType,
      'labor_unit_value': laborUnitValue,
      'crew_size': crewSize ?? 2,
      'calculation': calculation ?? {'labor_hours': 10.0, 'crew_size': 2.0},
      'item_total_cost': itemTotalCost ?? 20.0,
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
      'currency': currency ?? 'USD',
      'waste_percent': null,
      'quantity_provenance': null,
      'calculator_formula': null,
    };
  }

  static Map<String, dynamic> createEquipmentItemData({
    String? id,
    String? estimateId,
    String? itemName,
    String? description,
    String? pricingMethod,
    double? duration,
    double? dailyRate,
    double? jobAmount,
    double? deliveryFee,
    String? rateStatus,
    String? productLink,
    String? createdAt,
    String? updatedAt,
    Map<String, dynamic>? calculation,
    double? itemTotalCost,
    String? currency,
  }) {
    final method = pricingMethod ?? 'day';
    final days = duration ?? 3.0;
    final rate = dailyRate ?? 200.0;

    return {
      'id': id ?? 'item-equipment-1',
      'estimate_id': estimateId ?? 'estimate-123',
      'item_name': itemName ?? 'Test Equipment',
      'description': description ?? 'Test description',
      'item_type': 'equipment',
      'unit_price': null,
      'unit_measurement': null,
      'quantity': null,
      'pricing_method': method,
      'duration': method == 'day' ? days : null,
      'daily_rate': method == 'day' ? rate : null,
      'job_amount': method == 'job' ? jobAmount ?? 600.0 : null,
      'delivery_fee': deliveryFee,
      'rate_status': rateStatus ?? 'sample_rate_unverified',
      'product_link': productLink,
      'labor_calc_method': null,
      'labor_days': null,
      'labor_hours': null,
      'labor_unit_type': null,
      'labor_unit_value': null,
      'crew_size': null,
      'calculation':
          calculation ??
          (method == 'day'
              ? {'daily_rate': rate, 'duration': days}
              : {'job_amount': jobAmount ?? 600.0}),
      'item_total_cost':
          itemTotalCost ?? (method == 'day' ? days * rate : jobAmount ?? 600.0),
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
      'currency': currency ?? 'USD',
      'waste_percent': null,
      'quantity_provenance': null,
      'calculator_formula': null,
    };
  }

  static List<Map<String, dynamic>> createMixedItemsList({
    required String estimateId,
    int materialCount = 1,
    int laborCount = 1,
    int equipmentCount = 1,
  }) {
    final items = <Map<String, dynamic>>[];

    for (int i = 0; i < materialCount; i++) {
      items.add(
        createMaterialItemData(
          id: 'material-$i',
          estimateId: estimateId,
          itemName: 'Material Item $i',
        ),
      );
    }

    for (int i = 0; i < laborCount; i++) {
      items.add(
        createLaborItemData(
          id: 'labor-$i',
          estimateId: estimateId,
          itemName: 'Labor Item $i',
        ),
      );
    }

    for (int i = 0; i < equipmentCount; i++) {
      items.add(
        createEquipmentItemData(
          id: 'equipment-$i',
          estimateId: estimateId,
          itemName: 'Equipment Item $i',
        ),
      );
    }

    return items;
  }
}
