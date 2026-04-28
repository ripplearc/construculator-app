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
  }) {
    final price = unitPrice ?? 100.0;
    final qty = quantity ?? 5.0;

    return {
      'id': id ?? 'item-material-1',
      'estimate_id': estimateId ?? 'estimate-123',
      'item_name': itemName ?? 'Test Material',
      'description': description ?? 'Test description',
      'item_type': 'material',
      'unit_price': price,
      'unit_measurement': unit ?? 'pieces',
      'quantity': qty,
      'product_link': productLink,
      'labor_calc_method': null,
      'labor_days': null,
      'labor_hours': null,
      'labor_unit_type': null,
      'labor_unit_value': null,
      'crew_size': null,
      'calculation': calculation ?? {'unit_price': price, 'quantity': qty},
      'item_total_cost': itemTotalCost ?? price * qty,
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
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
      'product_link': productLink,
      'labor_calc_method': laborCalcMethod ?? 'hourly',
      'labor_days': laborDays,
      'labor_hours': laborHours ?? 10.0,
      'labor_unit_type': laborUnitType,
      'labor_unit_value': laborUnitValue,
      'crew_size': crewSize ?? 2,
      'calculation': calculation ?? {'labor_hours': 10.0, 'crew_size': 2.0},
      'item_total_cost': itemTotalCost ?? 20.0,
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
    };
  }

  static Map<String, dynamic> createEquipmentItemData({
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
  }) {
    final price = unitPrice ?? 200.0;
    final qty = quantity ?? 3.0;

    return {
      'id': id ?? 'item-equipment-1',
      'estimate_id': estimateId ?? 'estimate-123',
      'item_name': itemName ?? 'Test Equipment',
      'description': description ?? 'Test description',
      'item_type': 'equipment',
      'unit_price': price,
      'unit_measurement': unit ?? 'days',
      'quantity': qty,
      'product_link': productLink,
      'labor_calc_method': null,
      'labor_days': null,
      'labor_hours': null,
      'labor_unit_type': null,
      'labor_unit_value': null,
      'crew_size': null,
      'calculation': calculation ?? {'unit_price': price, 'quantity': qty},
      'item_total_cost': itemTotalCost ?? price * qty,
      'created_at': createdAt ?? '2024-01-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2024-01-01T00:00:00.000Z',
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
