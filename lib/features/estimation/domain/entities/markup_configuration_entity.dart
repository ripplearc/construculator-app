import 'package:construculator/features/estimation/domain/entities/enums/markup_type_enum.dart';
import 'package:construculator/features/estimation/domain/entities/enums/markup_value_type_enum.dart';

class MarkupValue {
  final MarkupValueType type;
  final double value;

  MarkupValue({required this.type, required this.value});
}

class MarkupConfiguration {
  final MarkupType overallType;
  final MarkupValue overallValue;
  final MarkupType? materialValueType;
  final MarkupValue? materialValue;
  final MarkupType? laborValueType;
  final MarkupValue? laborValue;
  final MarkupType? equipmentValueType;
  final MarkupValue? equipmentValue;

  MarkupConfiguration({
    required this.overallType,
    required this.overallValue,
    this.materialValueType,
    this.materialValue,
    this.laborValueType,
    this.laborValue,
    this.equipmentValueType,
    this.equipmentValue,
  });
}
