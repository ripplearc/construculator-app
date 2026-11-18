import 'package:construculator/features/estimation/domain/entities/cost_item_entity.dart';

final _stamp = DateTime.utc(2026, 11, 9);

MaterialCostItem materialLine({
  String id = 'm1',
  String name = 'Drywall sheets',
  double total = 211.34,
  double quantity = 13.25,
  Unit unit = Unit.sheets,
  double unitPrice = 14.5,
}) => MaterialCostItem(
  id: id,
  estimateId: 'e1',
  itemName: name,
  calculation: const {},
  itemTotalCost: total,
  createdAt: _stamp,
  updatedAt: _stamp,
  currency: 'USD',
  unitPrice: Money(amount: unitPrice),
  quantity: Quantity(value: quantity, unit: unit),
  rateStatus: RateStatus.ownRateConfirmed,
  quantityProvenance: QuantityProvenance.manual,
);

LaborCostItem laborLine({
  String id = 'l1',
  String name = 'Framing crew',
  double total = 480,
  LaborCalculationMethodType method = LaborCalculationMethodType.perHour,
  LaborValue value = const LaborValue(laborHours: 10),
  Map<String, double> calculation = const {},
  int? crewSize,
}) => LaborCostItem(
  id: id,
  estimateId: 'e1',
  itemName: name,
  calculation: calculation,
  itemTotalCost: total,
  createdAt: _stamp,
  updatedAt: _stamp,
  currency: 'USD',
  laborCalcMethod: method,
  laborValue: value,
  crewSize: crewSize,
);

EquipmentCostItem equipmentLine({
  String id = 'q1',
  String name = 'Scissor lift — 19ft',
  double total = 665,
  EquipmentPricingMethod method = EquipmentPricingMethod.day,
  double? duration = 4,
  Money? dailyRate = const Money(amount: 145),
  Money? jobAmount,
  Money? deliveryFee = const Money(amount: 85),
}) => EquipmentCostItem(
  id: id,
  estimateId: 'e1',
  itemName: name,
  calculation: const {},
  itemTotalCost: total,
  createdAt: _stamp,
  updatedAt: _stamp,
  currency: 'USD',
  pricingMethod: method,
  duration: duration,
  dailyRate: dailyRate,
  jobAmount: jobAmount,
  deliveryFee: deliveryFee,
  rateStatus: RateStatus.ownRateConfirmed,
);
